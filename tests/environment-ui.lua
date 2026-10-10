local function run()
  local environment = require 'core.environment'
  local original = vim.api.nvim_get_current_buf()
  local original_count = #vim.api.nvim_list_wins()
  vim.cmd 'TsienCheck'
  assert(environment.running, 'Check did not start')
  assert(
    vim.wait(15000, function()
      return not environment.running
    end),
    'Check did not finish'
  )
  local report = vim.api.nvim_get_current_buf()
  assert(report ~= original and vim.bo[report].buftype == 'nofile' and not vim.bo[report].modifiable)
  assert(#vim.api.nvim_list_wins() == original_count + 1)
  local content = table.concat(vim.api.nvim_buf_get_lines(report, 0, -1, false), '\n')
  assert(content:find('全部检查通过', 1, true), content)
  assert(not content:find('[失败]', 1, true) and not content:find('[缺少]', 1, true), content)
  assert(vim.fn.maparg('q', 'n', false, true).buffer == 1, 'Report close shortcut is missing')
  vim.api.nvim_feedkeys('q', 'xt', false)
  assert(vim.api.nvim_get_current_buf() == original and #vim.api.nvim_list_wins() == original_count)
  vim.cmd 'TsienCheck'
  assert(vim.wait(15000, function()
    return not environment.running
  end))
  assert(vim.api.nvim_get_current_buf() == report, 'Repeated checks created another report buffer')
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print 'ENVIRONMENT_UI_TESTS_OK: readable report, close shortcut, reusable window'
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
