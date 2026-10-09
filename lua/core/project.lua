local M = {}

local frontend_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
}

local oxfmt_markers = {
  '.oxfmtrc.json',
  '.oxfmtrc.jsonc',
  'oxfmt.config.ts',
}

local oxlint_markers = {
  '.oxlintrc.json',
  '.oxlintrc.jsonc',
  'oxlint.config.ts',
}

local eslint_markers = {
  '.eslintrc',
  '.eslintrc.js',
  '.eslintrc.cjs',
  '.eslintrc.yaml',
  '.eslintrc.yml',
  '.eslintrc.json',
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
  'eslint.config.ts',
  'eslint.config.mts',
  'eslint.config.cts',
}

local frontend_root_markers = {
  'package-lock.json',
  'pnpm-lock.yaml',
  'yarn.lock',
  'bun.lock',
  'bun.lockb',
}

local python_root_markers = {
  'pyrightconfig.json',
  'pyproject.toml',
  'uv.lock',
  'poetry.lock',
  'pdm.lock',
  'setup.py',
  'setup.cfg',
  'requirements.txt',
  'Pipfile',
  'tox.ini',
  'noxfile.py',
  'hatch.toml',
  'environment.yml',
  'environment.yaml',
  '.python-version',
  '.git',
}

local python_venv_names = {
  '.venv',
  'venv',
  '.env',
  'env',
}

local package_sections = {
  'dependencies',
  'devDependencies',
  'peerDependencies',
  'optionalDependencies',
}

local package_cache = {}
local node_bin_cache = {}
local typecheck_process

local function buf_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= '' then
    return vim.fs.dirname(name)
  end
  return vim.uv.cwd()
end

local function root_file(bufnr, names)
  return vim.fs.root(buf_dir(bufnr), names)
end

local function read_package(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    package_cache[path] = nil
    return nil
  end

  local mtime = stat.mtime or {}
  local stamp = table.concat({ stat.size or 0, mtime.sec or 0, mtime.nsec or 0 }, ':')
  local cached = package_cache[path]
  if cached and cached.stamp == stamp then
    return cached.data or nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    package_cache[path] = { stamp = stamp, data = false }
    return nil
  end

  local decoded_ok, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not decoded_ok or type(data) ~= 'table' then
    package_cache[path] = { stamp = stamp, data = false }
    return nil
  end

  package_cache[path] = { stamp = stamp, data = data }
  return data
end

local function package_paths(bufnr)
  return vim.fs.find('package.json', {
    upward = true,
    path = buf_dir(bufnr),
    limit = math.huge,
  })
end

local function package_dependency_root(bufnr, names)
  for _, path in ipairs(package_paths(bufnr)) do
    local data = read_package(path)
    if data then
      for _, section in ipairs(package_sections) do
        local dependencies = data[section]
        if type(dependencies) == 'table' then
          for _, name in ipairs(names) do
            if dependencies[name] ~= nil then
              return vim.fs.dirname(path)
            end
          end
        end
      end
    end
  end

  return nil
end

function M.is_frontend_filetype(filetype)
  return frontend_filetypes[filetype] == true
end

function M.python_root(bufnr)
  return root_file(bufnr, python_root_markers)
end

function M.frontend_root(bufnr)
  return root_file(bufnr, frontend_root_markers) or root_file(bufnr, { '.git' }) or root_file(bufnr, { 'package.json' })
end

local function python_from_prefix(prefix)
  if not prefix or prefix == '' then
    return nil
  end

  for _, path in ipairs {
    prefix .. '/bin/python',
    prefix .. '/Scripts/python.exe',
    prefix .. '/python.exe',
  } do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  return nil
end

function M.python_path_for_root(root)
  local active_python = python_from_prefix(vim.env.VIRTUAL_ENV) or python_from_prefix(vim.env.CONDA_PREFIX)
  if active_python then
    return active_python
  end

  root = root or vim.uv.cwd()
  for _, dirname in ipairs(python_venv_names) do
    local python = python_from_prefix(root .. '/' .. dirname)
    if python then
      return python
    end
  end

  return vim.fn.executable 'python3' == 1 and 'python3' or 'python'
end

function M.python_path(bufnr)
  return M.python_path_for_root(M.python_root(bufnr) or buf_dir(bufnr))
end

function M.oxfmt_root(bufnr)
  local root = root_file(bufnr, oxfmt_markers)
  if root then
    return root
  end

  return package_dependency_root(bufnr, { 'oxfmt', 'vite-plus' })
end

function M.oxlint_root(bufnr)
  local root = root_file(bufnr, oxlint_markers)
  if root then
    return root
  end

  return package_dependency_root(bufnr, { 'oxlint', 'vite-plus' })
end

function M.has_oxfmt(bufnr)
  return M.oxfmt_root(bufnr) ~= nil
end

function M.has_oxlint(bufnr)
  return M.oxlint_root(bufnr) ~= nil
end

function M.has_oxc_tooling(bufnr)
  return M.has_oxfmt(bufnr) or M.has_oxlint(bufnr)
end

function M.eslint_root(bufnr)
  if M.has_oxlint(bufnr) then
    return nil
  end

  local configured_root = root_file(bufnr, eslint_markers) or package_dependency_root(bufnr, { 'eslint' })
  if not configured_root then
    return nil
  end

  return M.frontend_root(bufnr) or configured_root
end

function M.find_node_bin(bufnr, name)
  local dir = buf_dir(bufnr)
  local cache_key = dir .. '\0' .. name
  if node_bin_cache[cache_key] ~= nil then
    return node_bin_cache[cache_key] or nil
  end

  local found
  for _, node_modules in ipairs(vim.fs.find('node_modules', { upward = true, path = dir, limit = math.huge })) do
    local bin = node_modules .. '/.bin/' .. name
    if vim.fn.executable(bin) == 1 then
      found = bin
      break
    end
  end

  if not found and vim.fn.executable(name) == 1 then
    found = name
  end

  -- Do not cache misses: package installation during a session should be visible.
  node_bin_cache[cache_key] = found
  return found
end

local function package_manager(bufnr)
  local options = {
    upward = true,
    path = buf_dir(bufnr),
    limit = 1,
  }
  local project_root = M.frontend_root(bufnr)
  if project_root then
    options.stop = vim.fs.dirname(project_root)
  end
  local lockfile = vim.fs.find(frontend_root_markers, options)[1]
  local name = lockfile and vim.fs.basename(lockfile) or nil

  if name == 'pnpm-lock.yaml' then
    return 'pnpm'
  elseif name == 'yarn.lock' then
    return 'yarn'
  elseif name == 'bun.lock' or name == 'bun.lockb' then
    return 'bun'
  end
  return 'npm'
end

local function typecheck_command(bufnr)
  for _, path in ipairs(package_paths(bufnr)) do
    local package = read_package(path)
    if package and type(package.scripts) == 'table' and type(package.scripts.typecheck) == 'string' then
      local root = vim.fs.dirname(path)
      local manager = package_manager(bufnr)
      if vim.fn.executable(manager) == 0 then
        return nil, nil, ('%s is required to run the project typecheck script'):format(manager)
      end
      return { manager, 'run', 'typecheck' }, root
    end
  end

  local tsc = M.find_node_bin(bufnr, 'tsc')
  if not tsc then
    return nil, nil, 'No typecheck script or project-local tsc executable found'
  end
  return { tsc, '--noEmit', '--pretty', 'false' }, M.frontend_root(bufnr) or buf_dir(bufnr)
end

local function typecheck_items(output, cwd)
  local items = {}
  for _, line in ipairs(vim.split(output, '\n', { trimempty = true })) do
    local file, lnum, col, severity, code, message = line:match '^(.-)%((%d+),(%d+)%)%: (%w+) TS(%d+)%: (.*)$'
    if file then
      local is_absolute = vim.startswith(file, '/') or file:match '^%a:[/\\]' or vim.startswith(file, '\\\\')
      if not is_absolute then
        file = vim.fs.joinpath(cwd, file)
      end
      table.insert(items, {
        filename = vim.fs.normalize(file),
        lnum = tonumber(lnum),
        col = tonumber(col),
        type = severity == 'warning' and 'W' or 'E',
        nr = tonumber(code),
        text = message,
      })
    end
  end
  return items
end

function M.typecheck(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if typecheck_process then
    vim.notify('Typecheck is already running', vim.log.levels.WARN)
    return
  end

  local command, cwd, err = typecheck_command(bufnr)
  if not command then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  vim.notify(('Running %s'):format(table.concat(command, ' ')), vim.log.levels.INFO)
  typecheck_process = vim.system(command, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      typecheck_process = nil
      local output = table.concat({ result.stdout or '', result.stderr or '' }, '\n')
      local items = typecheck_items(output, cwd)
      vim.fn.setqflist({}, ' ', {
        title = 'Typecheck: ' .. cwd,
        items = items,
        context = { cwd = cwd, command = command },
      })

      if result.code == 0 then
        vim.notify('Typecheck passed', vim.log.levels.INFO)
      elseif #items > 0 then
        vim.cmd.copen()
        vim.notify(('Typecheck failed with %d error(s)'):format(#items), vim.log.levels.ERROR)
      else
        local message = vim.trim(output)
        vim.notify(message ~= '' and message or ('Typecheck exited with code %d'):format(result.code), vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
