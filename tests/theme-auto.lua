-- Run after VimEnter so OptionSet fires for runtime 'background' changes:
-- nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' '+autocmd VimEnter * ++nested luafile tests/theme-auto.lua'
local function run()
  local config = require 'core.config'
  local theme = require 'core.theme'

  config.colorscheme = 'auto'
  config.background_themes = { dark = 'tsien-dark', light = 'tsien-light' }

  vim.o.background = 'dark'
  theme.setup()
  theme.apply()
  assert(vim.g.colors_name == 'tsien-dark' and vim.o.background == 'dark', 'Auto mode did not start dark')

  vim.o.background = 'light'
  vim.wait(300)
  assert(vim.g.colors_name == 'tsien-light' and vim.o.background == 'light', 'Background change did not load the light theme')

  vim.o.background = 'dark'
  vim.wait(300)
  assert(vim.g.colors_name == 'tsien-dark' and vim.o.background == 'dark', 'Background change did not load the dark theme')

  vim.cmd.colorscheme 'default'
  vim.o.background = 'light'
  vim.wait(300)
  assert(vim.g.colors_name == 'default', 'Auto mode overrode a manually selected third-party theme')

  vim.o.background = 'dark'
  vim.wait(300)
  vim.cmd.colorscheme 'tsien-light'
  assert(vim.g.colors_name == 'tsien-light' and vim.o.background == 'light', 'Manual light theme load did not set its background')

  config.colorscheme = 'tsien-dark'
  theme.apply()
  assert(vim.g.colors_name == 'tsien-dark' and vim.o.background == 'dark', 'Fixed mode did not load its theme')
  vim.o.background = 'light'
  vim.wait(300)
  assert(
    vim.g.colors_name == 'tsien-dark' and vim.o.background == 'dark',
    'Fixed mode did not restore its background'
  )

  print('THEME_AUTO_TESTS_OK: runtime switching, manual overrides and fixed mode')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
else
  vim.cmd 'qa!'
end
