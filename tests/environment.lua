local environment = require 'core.environment'
local dependencies = require 'core.dependencies'

local function run()
  assert(vim.fn.exists ':TsienCheck' == 2 and vim.fn.exists ':TsienSetup' == 2)
  assert(not require('lazy.core.config').plugins['mason.nvim']._.loaded, 'Environment commands loaded Mason at startup')

  local original_run, original_probe = environment.run, environment.probe
  local executable, system = vim.fn.executable, vim.system
  local ts = require 'nvim-treesitter'
  local install = ts.install
  local language_add, query_get = vim.treesitter.language.add, vim.treesitter.query.get
  local notify_once, notify = vim.notify_once, vim.notify
  local warnings = {}
  vim.notify_once = function(message)
    warnings[#warnings + 1] = message
  end
  vim.notify = function() end

  -- Version checks must reject an old CLI and failed/unparseable output.
  local response
  environment.run = function(_, _, callback)
    callback(response)
  end
  for _, fixture in ipairs {
    { 'tree-sitter 0.25.9', 0, false },
    { 'tree-sitter 0.26.13', 0, true },
    { 'tree-sitter 0.26.13', 1, false },
    { 'broken tool', 0, false },
  } do
    response = { stdout = fixture[1], stderr = '', code = fixture[2] }
    environment.probe({ name = 'tree-sitter', minimum = '0.26.1' }, function(ok)
      assert(ok == fixture[3])
    end)
  end
  vim.fn.executable = function(name)
    return name == 'tree-sitter' and 0 or executable(name)
  end
  environment.probe({ name = 'tree-sitter', minimum = '0.26.1' }, function(ok, reason)
    assert(not ok and reason:find('缺少命令', 1, true))
  end)
  vim.fn.executable = executable

  -- A broken rustup component must fall back to Mason rather than its proxy.
  local calls = 0
  vim.system = function(command, opts)
    assert(command[1] == 'rustup' and command[2] == 'which' and opts.cwd)
    calls = calls + 1
    return {
      wait = function()
        return { code = 1, stdout = '', stderr = 'missing component' }
      end,
    }
  end
  local analyzer = environment.rust_analyzer()
  assert(analyzer == vim.fn.stdpath 'data' .. '/mason/bin/rust-analyzer' and calls == 1)
  vim.system = system

  -- Coalesce requests; every waiting buffer must be notified exactly once.
  local probe_callback, install_callback, installed, count = nil, nil, false, 0
  environment.probe = function(_, callback)
    probe_callback = callback
  end
  ts.install = function(languages, options)
    assert(type(languages[1]) == 'string' and options.force == true)
    count = count + 1
    return {
      await = function(_, callback)
        install_callback = callback
      end,
    }
  end
  vim.treesitter.language.add = function()
    return installed
  end
  vim.treesitter.query.get = setmetatable({ clear = function() end }, {
    __call = function()
      return {}
    end,
  })
  local notified = 0
  environment.ensure_parser('rust', function(ok)
    assert(ok)
    notified = notified + 1
  end)
  environment.ensure_parser('rust', function(ok)
    assert(ok)
    notified = notified + 1
  end)
  assert(count == 0)
  probe_callback(true)
  assert(count == 1)
  installed = true
  install_callback(nil, true)
  assert(
    vim.wait(1000, function()
      return notified == 2
    end),
    'Waiting buffers were not resumed'
  )

  -- A failed language is not repeatedly downloaded on every FileType event.
  local failures = 0
  environment.ensure_parser('python', function(ok)
    assert(not ok)
    failures = failures + 1
  end)
  probe_callback(false, 'CLI unavailable')
  environment.ensure_parser('python', function(ok)
    assert(not ok)
    failures = failures + 1
  end)
  assert(failures == 2 and #warnings == 1 and count == 1)
  environment.ensure_parser('vue', function(ok)
    assert(not ok)
    failures = failures + 1
  end)
  probe_callback(true)
  install_callback('network failed', false)
  assert(vim.wait(1000, function()
    return failures == 3
  end))
  assert(#warnings == 2 and warnings[2]:find('network failed', 1, true))

  environment.run, environment.probe = original_run, original_probe
  ts.install = install
  vim.treesitter.language.add, vim.treesitter.query.get = language_add, query_get
  vim.notify_once, vim.notify = notify_once, notify

  -- A subprocess that cannot spawn must call its completion handler, not hang.
  local spawned
  environment.run({ '/nonexistent/tsien-command' }, {}, function(result)
    spawned = result.code
  end)
  assert(vim.wait(1000, function()
    return spawned ~= nil
  end) and spawned == 127)

  -- A failed registry refresh must not become a successful setup merely because
  -- previously installed tools still exist. No actual installers run in this test.
  require('lazy').load { plugins = { 'mason.nvim' } }
  local registry = require 'mason-registry'
  local refresh = registry.refresh
  registry.refresh = function(callback)
    callback(false)
  end
  local requirements = dependencies.system
  dependencies.system = { { name = 'tree-sitter', brew = 'tree-sitter-cli', minimum = '0.26.1' } }
  local upgraded, brew_calls = false, 0
  environment.run = function(command, _, callback)
    if command[1] == 'brew' then
      assert(command[2] == 'upgrade' and command[3] == 'tree-sitter-cli')
      upgraded = true
      brew_calls = brew_calls + 1
    else
      assert(command[1] == 'rustup' or command[2] == '--version' or command[2] == 'clippy')
    end
    callback { code = 0, stdout = 'test version 99.0.0\nrust-src', stderr = '' }
  end
  environment.probe = function(_, callback)
    callback(upgraded, 'old CLI')
  end
  local setup_finished
  environment.setup({ show = false }, function(ok, lines)
    assert(not ok)
    assert(table.concat(lines, '\n'):find('无法更新工具安装目录', 1, true))
    setup_finished = true
  end)
  assert(environment.setup { show = false } == false, 'Concurrent setup started a second installer')
  assert(vim.wait(5000, function()
    return setup_finished
  end) and not environment.running)
  assert(brew_calls == 1)
  dependencies.system = requirements
  registry.refresh = refresh
  environment.run, environment.probe = original_run, original_probe

  -- Real read-only verification after the simulations.
  local done
  environment.check({ show = false }, function(ok)
    assert(ok)
    done = true
  end)
  assert(vim.wait(15000, function()
    return done
  end))
  print 'ENVIRONMENT_TESTS_OK'
end

vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    print(err)
    vim.cmd 'cquit 1'
  else
    vim.cmd 'qa!'
  end
end, 100)
