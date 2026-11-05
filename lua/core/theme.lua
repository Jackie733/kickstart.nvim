local M = {}

local config = require 'core.config'
local loading = false

local function term_background()
  local value = vim.env.COLORFGBG
  if not value then
    return nil
  end
  local index = tonumber(value:match(';([0-9]+)%s*$'))
  if not index or index > 15 then
    return nil
  end
  return (index == 7 or index >= 9) and 'light' or 'dark'
end

-- Neovim's TUI sets 'background' from an OSC 11 query. COLORFGBG is a fallback for
-- terminals that do not answer the query but still export their palette.
local function detected_background()
  if vim.api.nvim_get_option_info2('background', {}).was_set then
    return vim.o.background
  end
  return term_background() or vim.o.background
end

local function theme_backgrounds()
  local themes = config.background_themes or {}
  return {
    [themes.dark or 'tsien-dark'] = 'dark',
    [themes.light or 'tsien-light'] = 'light',
  }
end

function M.target()
  if config.colorscheme ~= 'auto' then
    return config.colorscheme
  end
  local themes = config.background_themes or {}
  if detected_background() == 'light' then
    return themes.light or 'tsien-light'
  end
  return themes.dark or 'tsien-dark'
end

function M.apply()
  if loading then
    return
  end
  loading = true
  local name = M.target()
  -- Clearing this before the theme can change 'background' prevents a reload loop.
  vim.g.colors_name = nil
  local ok, err = pcall(vim.cmd.colorscheme, name)
  loading = false
  if not ok then
    error(err)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('TsienTheme', { clear = true })
  local backgrounds = theme_backgrounds()

  -- Neovim reloads the active colorscheme when 'background' changes. If the terminal
  -- background no longer matches the loaded theme, let the reload follow the terminal
  -- instead of letting the colorscheme force its old value back.
  vim.api.nvim_create_autocmd('ColorSchemePre', {
    group = group,
    callback = function()
      local expected = vim.g.colors_name and backgrounds[vim.g.colors_name]
      vim.g.tsien_background_reload = expected ~= nil and expected ~= vim.o.background
    end,
  })

  vim.api.nvim_create_autocmd('OptionSet', {
    group = group,
    pattern = 'background',
    callback = function()
      if loading or not vim.g.colors_name then
        return
      end
      local expected = backgrounds[vim.g.colors_name]
      if not expected then
        return
      end
      if config.colorscheme == 'auto' then
        if vim.g.colors_name ~= M.target() then
          M.apply()
        end
      elseif expected ~= vim.o.background then
        M.apply()
      end
    end,
  })
end

return M
