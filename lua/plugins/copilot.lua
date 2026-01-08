-- GitHub Copilot
return {
  'github/copilot.vim',
  event = 'InsertEnter',
  keys = {
    {
      '<C-y>',
      function()
        return vim.fn['copilot#Accept']('<CR>')
      end,
      mode = 'i',
      expr = true,
      replace_keycodes = false,
      silent = true,
      desc = 'Copilot Accept',
    },
    {
      '<M-]>',
      function()
        return vim.fn['copilot#Next']()
      end,
      mode = 'i',
      expr = true,
      silent = true,
      desc = 'Copilot Next',
    },
    {
      '<M-[>',
      function()
        return vim.fn['copilot#Previous']()
      end,
      mode = 'i',
      expr = true,
      silent = true,
      desc = 'Copilot Previous',
    },
    {
      '<C-]>',
      function()
        return vim.fn['copilot#Dismiss']()
      end,
      mode = 'i',
      expr = true,
      silent = true,
      desc = 'Copilot Dismiss',
    },
  },
  init = function()
    vim.g.copilot_no_tab_map = true -- avoid clashing with blink.cmp
    vim.g.copilot_assume_mapped = true
  end,
}
