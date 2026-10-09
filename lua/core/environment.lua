local M = { running = false }
local dependencies = require 'core.dependencies'
local parser_jobs, parser_failed = {}, {}
local report_buf
local task_cwd

local function project_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= '' then
    return task_cwd or vim.fn.getcwd()
  end
  return name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd()
end
local log_path = vim.fn.stdpath 'state' .. '/tsien-environment.log'

local function append(lines, message)
  for _, line in ipairs(vim.split(tostring(message), '\n', { plain = true })) do
    lines[#lines + 1] = line
  end
  if report_buf and vim.api.nvim_buf_is_valid(report_buf) then
    vim.bo[report_buf].modifiable = true
    vim.api.nvim_buf_set_lines(report_buf, 0, -1, false, lines)
    vim.bo[report_buf].modifiable = false
  end
end

local function report(title, show)
  local lines = { title, '日志：' .. log_path, '' }
  if show ~= false then
    if not report_buf or not vim.api.nvim_buf_is_valid(report_buf) then
      report_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(report_buf, 'TsienVim 环境检查')
      vim.bo[report_buf].buftype = 'nofile'
      vim.bo[report_buf].bufhidden = 'hide'
      vim.bo[report_buf].swapfile = false
      vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = report_buf })
    end
    local win = vim.fn.bufwinid(report_buf)
    if win == -1 then
      vim.cmd 'botright vnew'
      vim.api.nvim_win_set_buf(0, report_buf)
    else
      vim.api.nvim_set_current_win(win)
    end
    append(lines, '检查进行中…')
  end
  return lines
end

local function finish(lines, ok, callback)
  append(lines, ok and '\n完成：全部检查通过。' or '\n尚有未解决项目，请查看上面的原因，修复后重新运行 :TsienSetup。')
  vim.fn.mkdir(vim.fn.stdpath 'state', 'p')
  vim.fn.writefile(lines, log_path)
  M.running = false
  if callback then
    callback(ok, lines)
  end
end

-- System checks and installers run asynchronously with bounded subprocesses.
function M.run(command, opts, callback)
  opts = vim.tbl_extend('force', { text = true, timeout = 10000, cwd = task_cwd }, opts or {})
  local ok, err = pcall(vim.system, command, opts, vim.schedule_wrap(callback))
  if not ok then
    vim.schedule(function()
      callback { code = 127, stderr = tostring(err), stdout = '' }
    end)
  end
end

local function each(items, action, done)
  local index = 0
  local function next_item()
    index = index + 1
    if items[index] then
      action(items[index], next_item)
    else
      done()
    end
  end
  next_item()
end

function M.probe(spec, callback)
  if vim.fn.executable(spec.name) ~= 1 then
    callback(false, '缺少命令 ' .. spec.name)
    return
  end
  -- Only executables with a required version need a subprocess.
  if not spec.minimum then
    callback(true, vim.fn.exepath(spec.name))
    return
  end
  M.run({ spec.name, '--version' }, {}, function(result)
    local version = vim.version.parse((result.stdout or '') .. (result.stderr or ''))
    local ok = result.code == 0 and version and vim.version.ge(version, spec.minimum)
    callback(
      not not ok,
      ok and tostring(version) or ('版本不可用或低于 ' .. spec.minimum .. '：' .. vim.trim((result.stdout or '') .. (result.stderr or '')))
    )
  end)
end

function M.packages()
  local packages = vim.tbl_values(dependencies.servers)
  vim.list_extend(packages, dependencies.tools)
  packages[#packages + 1] = 'rust-analyzer'
  table.sort(packages)
  return packages
end

local function load_mason()
  require('lazy').load { plugins = { 'mason.nvim' } }
  return require 'mason-registry'
end

local function package_usable(package)
  if not package:is_installed() then
    return false
  end
  for executable in pairs(package.spec.bin or {}) do
    if vim.fn.executable(executable) ~= 1 then
      return false
    end
  end
  return true
end

local function refresh_runtime()
  local install_dir = vim.fs.normalize(require('nvim-treesitter.config').get_install_dir '')
  vim.opt.runtimepath:remove(install_dir)
  vim.opt.runtimepath:prepend(install_dir)
end

local function parser_status(lang)
  local ok, loaded, problem = pcall(vim.treesitter.language.add, lang)
  if not ok or not loaded then
    return false, '解析器缺失或无法加载：' .. tostring(problem or loaded)
  end
  for _, group in ipairs { 'highlights', 'indents', 'injections' } do
    local query_ok, err = pcall(vim.treesitter.query.get, lang, group)
    if not query_ok then
      return false, group .. ' 不兼容：' .. tostring(err)
    end
    if group == 'highlights' and not err then
      return false, '缺少高亮规则'
    end
  end
  return true
end

-- Evaluate in the opened project's directory, only when Rust is requested.
-- A rustup proxy being executable does not mean that its component is installed.
function M.rust_analyzer(bufnr, directory)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  local cwd = directory or (name ~= '' and vim.fs.dirname(name) or vim.fn.getcwd())
  if vim.fn.executable 'rustup' == 1 then
    local ok, result = pcall(function()
      return vim.system({ 'rustup', 'which', 'rust-analyzer' }, { cwd = cwd, text = true }):wait(1000)
    end)
    if ok and result.code == 0 then
      local path = vim.trim(result.stdout or '')
      if vim.fn.executable(path) == 1 then
        return path
      end
    end
  end
  local fallback = vim.fn.stdpath 'data' .. '/mason/bin/rust-analyzer'
  if vim.fn.executable(fallback) == 1 then
    return fallback
  end
  local external = vim.fn.exepath 'rust-analyzer'
  local proxy = (vim.env.CARGO_HOME or (vim.uv.os_homedir() .. '/.cargo')) .. '/bin/rust-analyzer'
  if external ~= '' and vim.uv.fs_realpath(external) ~= vim.uv.fs_realpath(proxy) then
    return external
  end
end

local function inspect(lines, callback)
  local all_ok = vim.fn.has 'nvim-0.12' == 1
  append(lines, (all_ok and '[正常] ' or '[失败] ') .. 'Neovim ' .. tostring(vim.version()) .. '（要求至少 0.12）')
  each(dependencies.system, function(spec, next_item)
    M.probe(spec, function(ok, detail)
      all_ok = all_ok and ok
      append(lines, (ok and '[正常] ' or '[失败] ') .. spec.name .. '：' .. detail)
      next_item()
    end)
  end, function()
    for _, lang in ipairs(dependencies.parsers) do
      local ok, detail = parser_status(lang)
      all_ok = all_ok and ok
      append(lines, (ok and '[正常] ' or '[失败] ') .. '语法解析 ' .. lang .. (detail and '：' .. detail or ''))
    end
    local registry_ok, registry = pcall(load_mason)
    if not registry_ok then
      append(lines, '[失败] 无法加载工具管理器：' .. tostring(registry))
      all_ok = false
    end
    for _, name in ipairs(M.packages()) do
      local found, package = pcall(function()
        return registry.get_package(name)
      end)
      local installed = found and package_usable(package)
      all_ok = all_ok and installed
      append(lines, (installed and '[正常] ' or '[缺少] ') .. name)
    end
    local analyzer = M.rust_analyzer(0, task_cwd)
    local rust_checks =
      { { 'cargo', '--version' }, { 'rustfmt', '--version' }, { 'cargo', 'clippy', '--version' }, { 'rustup', 'component', 'list', '--installed' } }
    if analyzer then
      table.insert(rust_checks, { analyzer, '--version' })
    else
      all_ok = false
      append(lines, '[失败] Rust 分析工具：当前工具链和备用工具均不可用')
    end
    each(rust_checks, function(command, next_item)
      M.run(command, {}, function(result)
        local ok = result.code == 0
        if command[2] == 'component' then
          ok = ok and (result.stdout or ''):find('rust-src', 1, true) ~= nil
        end
        all_ok = all_ok and ok
        append(lines, (ok and '[正常] ' or '[失败] ') .. table.concat(command, ' ') .. '：' .. vim.trim((result.stdout or '') .. (result.stderr or '')))
        next_item()
      end)
    end, function()
      callback(all_ok)
    end)
  end)
end

function M.check(opts, callback)
  opts = opts or {}
  if M.running then
    vim.notify('环境任务正在进行，请等待完成。', vim.log.levels.WARN)
    return false
  end
  task_cwd = project_dir()
  M.running = true
  local lines = report('TsienVim 环境检查', opts.show)
  inspect(lines, function(ok)
    finish(lines, ok, callback)
  end)
  return true
end

local function system_setup(lines, done)
  each(dependencies.system, function(spec, next_item)
    M.probe(spec, function(ok, detail)
      if ok then
        next_item()
      elseif vim.fn.has 'mac' == 1 and spec.brew and vim.fn.executable 'brew' == 1 then
        append(lines, '[安装] ' .. spec.name .. '：' .. detail)
        -- brew install is also idempotent when a shared formula was installed above.
        local prefix = vim.fs.dirname(vim.fs.dirname(vim.fn.exepath 'brew'))
        local installed = vim.fn.isdirectory(prefix .. '/opt/' .. spec.brew) == 1
        M.run({ 'brew', installed and 'upgrade' or 'install', spec.brew }, {
          timeout = 600000,
          env = { HOMEBREW_NO_AUTO_UPDATE = '1', HOMEBREW_NO_INSTALL_CLEANUP = '1' },
        }, function(result)
          append(lines, (result.code == 0 and '[已安装] ' or '[失败] ') .. spec.brew .. '\n' .. vim.trim((result.stdout or '') .. (result.stderr or '')))
          next_item()
        end)
      else
        append(lines, '[需手动处理] ' .. spec.name .. '：' .. (spec.help or ('请使用系统包管理器安装 ' .. (spec.brew or spec.name))))
        next_item()
      end
    end)
  end, function()
    if vim.fn.executable 'rustup' ~= 1 then
      done()
      return
    end
    local function components()
      append(lines, '[检查并安装] 当前项目的 Rust 分析、格式化、检查及标准库源码组件')
      M.run({ 'rustup', 'component', 'add', 'rust-analyzer', 'rustfmt', 'clippy', 'rust-src' }, { timeout = 600000 }, function(result)
        append(lines, (result.code == 0 and '[正常] ' or '[失败] ') .. 'Rust 组件\n' .. vim.trim((result.stdout or '') .. (result.stderr or '')))
        done()
      end)
    end
    M.run({ 'rustup', 'show', 'active-toolchain' }, { timeout = 600000 }, function(result)
      local override = vim.fs.find({ 'rust-toolchain', 'rust-toolchain.toml' }, { upward = true, path = task_cwd })[1]
      if result.code ~= 0 and not override then
        M.run({ 'rustup', 'default' }, {}, function(current)
          if current.code == 0 then
            components()
            return
          end
          append(lines, '[安装] 首次使用 Rust，准备默认 stable 工具链')
          M.run({ 'rustup', 'default', 'stable' }, { timeout = 600000 }, function(installed)
            if installed.code ~= 0 then
              append(lines, '[失败] 无法安装 Rust 工具链：' .. (installed.stderr or ''))
            end
            components()
          end)
        end)
      else
        components()
      end
    end)
  end)
end

local function mason_setup(lines, done)
  local loaded, registry = pcall(load_mason)
  if not loaded then
    append(lines, '[失败] 无法加载工具管理器：' .. tostring(registry))
    done()
    return
  end
  registry.refresh(vim.schedule_wrap(function(ok)
    if not ok then
      append(lines, '[失败] 无法更新工具安装目录，请检查网络；详情见 :MasonLog。')
      done()
      return
    end
    each(M.packages(), function(name, next_item)
      local found, package = pcall(function()
        return registry.get_package(name)
      end)
      if not found then
        append(lines, '[失败] 安装目录中没有 ' .. name)
        next_item()
      elseif package_usable(package) then
        next_item()
      else
        append(lines, '[安装] ' .. name)
        local completed = false
        local function complete(success, err)
          if completed then
            return
          end
          completed = true
          vim.schedule(function()
            append(
              lines,
              (success and '[已安装] ' or '[失败] ')
                .. name
                .. (not success and err and ('：' .. tostring(err)) or '')
                .. (not success and '；详情见 :MasonLog。' or '')
            )
            next_item()
          end)
        end
        if package:is_installing() then
          package:once('install:success', function()
            complete(true)
          end)
          package:once('install:failed', function()
            complete(false, '其他安装任务失败')
          end)
        else
          local started, err = pcall(function()
            package:install({ force = package:is_installed() }, complete)
          end)
          if not started then
            complete(false, err)
          end
        end
      end
    end, done)
  end))
end

local function parser_setup(lines, force, done)
  M.probe({ name = 'tree-sitter', minimum = '0.26.1' }, function(ok, detail)
    if not ok or vim.fn.executable 'cc' ~= 1 then
      append(lines, '[失败] 不能构建语法解析器：' .. (not ok and detail or '缺少 C 编译器'))
      done()
      return
    end
    append(lines, '[检查] 语法解析器与当前插件版本是否匹配')
    local ts = require 'nvim-treesitter'
    local languages = {}
    for _, lang in ipairs(dependencies.parsers) do
      if force or not parser_status(lang) then
        languages[#languages + 1] = lang
      end
    end
    if #languages > 0 then
      append(lines, '[安装] 构建 ' .. #languages .. ' 个语法解析器')
    end
    local function updated(err, success)
      vim.schedule(function()
        refresh_runtime()
        append(
          lines,
          (not err and success and '[正常] ' or '[失败] ')
            .. '解析器版本同步'
            .. (err and ('：' .. tostring(err)) or '；安装详情见 :TSLog。')
        )
        done()
      end)
    end
    local task = ts.install(languages, { force = true, max_jobs = 4 })
    task:await(function(err, success)
      if err or not success then
        updated(err, success)
      else
        ts.update(dependencies.parsers, { max_jobs = 4 }):await(updated)
      end
    end)
  end)
end

function M.setup(opts, callback)
  opts = opts or {}
  if M.running then
    vim.notify('环境任务正在进行，请等待完成。', vim.log.levels.WARN)
    return false
  end
  task_cwd = project_dir()
  M.running = true
  if next(parser_jobs) then
    M.running = false
    vim.notify('语法解析器正在后台安装，请完成后再运行 :TsienSetup。', vim.log.levels.WARN)
    return false
  end
  parser_failed = {}
  local lines = report('TsienVim 初始化与修复', opts.show)
  system_setup(lines, function()
    mason_setup(lines, function()
      parser_setup(lines, opts.force, function()
        append(lines, '\n安装结束，正在核实实际可用情况…')
        inspect(lines, function(ok)
          for _, line in ipairs(lines) do
            if vim.startswith(line, '[失败]') or vim.startswith(line, '[需手动处理]') then
              ok = false
            end
          end
          finish(lines, ok, callback)
          vim.notify(
            ok and '环境准备完成。已打开的文件可重新载入；更新解析器后请重启 Neovim。'
              or '环境仍有问题，请查看检查结果。',
            ok and vim.log.levels.INFO or vim.log.levels.WARN
          )
        end)
      end)
    end)
  end)
  return true
end

-- Missing parsers are installed once per language per session, outside file drawing.
function M.ensure_parser(lang, callback)
  if M.running then
    callback(false)
    return
  end
  if parser_failed[lang] then
    callback(false)
    return
  end
  if parser_jobs[lang] then
    table.insert(parser_jobs[lang], callback)
    return
  end
  parser_jobs[lang] = { callback }
  local function complete(ok, reason)
    local callbacks = parser_jobs[lang]
    parser_jobs[lang] = nil
    parser_failed[lang] = not ok
    if not ok then
      vim.notify_once(
        '无法准备 ' .. lang .. ' 语法解析器：' .. tostring(reason) .. '\n运行 :TsienSetup 修复；用 :TsienCheck 查看环境。',
        vim.log.levels.WARN
      )
    end
    for _, cb in ipairs(callbacks) do
      cb(ok)
    end
  end
  M.probe({ name = 'tree-sitter', minimum = '0.26.1' }, function(ok, detail)
    if not ok or vim.fn.executable 'cc' ~= 1 then
      complete(false, not ok and detail or '缺少 C 编译器')
      return
    end
    local ts = require 'nvim-treesitter'
    ts.install({ lang }, { force = true, max_jobs = 1 }):await(function(err, success)
      vim.schedule(function()
        -- Neovim caches which runtime directories contain parsers. Installing
        -- the first parser creates a directory that was absent from that cache.
        refresh_runtime()
        local usable, problem = parser_status(lang)
        complete(not err and success and usable, err or problem or '下载或编译失败；详情见 :TSLog')
      end)
    end)
  end)
end

function M.register()
  vim.api.nvim_create_user_command('TsienCheck', function()
    M.check()
  end, { desc = '检查语言环境与依赖' })
  vim.api.nvim_create_user_command('TsienSetup', function(args)
    M.setup { force = args.bang }
  end, { bang = true, desc = '初始化并修复依赖；! 重建全部语法解析器' })
end

return M
