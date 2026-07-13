local M = {}

local state = {
  win = nil,
  group = vim.api.nvim_create_augroup('markdown-image-preview', { clear = true }),
}

local function refresh_tmux()
  if vim.env.TMUX and vim.fn.executable('tmux') == 1 then
    vim.system({ 'tmux', 'refresh-client' }, {}, function() end)
  end
end

local function redraw()
  vim.cmd('redraw!')
  vim.defer_fn(function()
    pcall(vim.cmd, 'redraw!')
    refresh_tmux()
  end, 20)
end

local function close_window()
  vim.api.nvim_clear_autocmds({ group = state.group })

  local closed = false
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
    closed = true
  end

  state.win = nil

  if closed then
    redraw()
  end
end

local function tmux_passthrough(data)
  if not vim.env.TMUX then
    return data
  end

  return '\027Ptmux;' .. data:gsub('\027', '\027\027') .. '\027\\'
end

local function send_ui(data)
  if vim.api.nvim_ui_send then
    for index = 1, #data, 8192 do
      vim.api.nvim_ui_send(data:sub(index, index + 8191))
    end
  else
    io.stdout:write(data)
    io.stdout:flush()
  end
end

local function send_graphics(data)
  send_ui(tmux_passthrough(data))
end

local function cursor_to(row, col)
  send_ui(('\027[%d;%dH'):format(row, col))
end

local function read_file(path)
  local file = io.open(path, 'rb')
  if not file then
    return nil
  end

  local data = file:read('*a')
  file:close()
  return data
end

local function image_size(path)
  if vim.fn.executable('identify') ~= 1 then
    return nil
  end

  local output = vim.fn.systemlist({ 'identify', '-format', '%w %h', path })
  if vim.v.shell_error ~= 0 or not output[1] then
    return nil
  end

  local width, height = output[1]:match('^(%d+)%s+(%d+)$')
  if not width or not height then
    return nil
  end

  return tonumber(width), tonumber(height)
end

local function fit_size(path)
  local max_width = math.max(24, math.min(80, math.floor(vim.o.columns * 0.45)))
  local max_height = math.max(10, math.min(35, math.floor(vim.o.lines * 0.55)))
  local width, height = image_size(path)

  if not width or not height or width == 0 or height == 0 then
    return max_width, max_height
  end

  local cell_ratio = 0.5
  local cols = max_width
  local rows = math.max(1, math.ceil(cols * height / width * cell_ratio))

  if rows > max_height then
    rows = max_height
    cols = math.max(1, math.ceil(rows * width / height / cell_ratio))
  end

  return math.min(cols, max_width), math.min(rows, max_height)
end

local function normalize_src(src)
  src = vim.trim(src or '')
  src = src:gsub('^<', ''):gsub('>$', '')
  src = src:gsub('^["\']', ''):gsub('["\']$', '')
  src = src:gsub('%%20', ' ')

  if src:match('^https?://') then
    return nil, 'Remote image URLs are not supported by this preview.'
  end

  if src == '' then
    return nil, 'No image path found on the current line.'
  end

  if src:sub(1, 1) == '/' then
    return vim.fs.normalize(src)
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  local base = current_file ~= '' and vim.fs.dirname(current_file) or vim.fn.getcwd()
  return vim.fs.normalize(base .. '/' .. src)
end

local function image_src_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local src = line:match('!%[[^%]]*%]%(([^%)]+)%)')

  if src then
    return src
  end

  return line:match("<img%s+.-src=[\"']([^\"']+)[\"']")
end

local function show_iterm_image(path, row, col, width, height)
  local data = read_file(path)
  if not data then
    vim.notify('Unable to read image: ' .. path, vim.log.levels.ERROR)
    close_window()
    return
  end

  cursor_to(row, col)

  local name = vim.base64.encode(vim.fs.basename(path))
  local payload = vim.base64.encode(data)
  local sequence = ('\027]1337;File=name=%s;inline=1;width=%d;height=%d;preserveAspectRatio=1;doNotMoveCursor=1:%s\a'):format(
    name,
    width,
    height,
    payload
  )

  send_graphics(sequence)
end

local function show_iterm(path)
  local width, height = fit_size(path)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}

  for _ = 1, height do
    lines[#lines + 1] = string.rep(' ', width)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'none',
    focusable = false,
  })

  state.win = win

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].cursorline = false
  vim.wo[win].winblend = 100
  vim.wo[win].winhighlight = 'NormalFloat:Normal'

  vim.api.nvim_clear_autocmds({ group = state.group })
  vim.api.nvim_create_autocmd({ 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinScrolled', 'VimResized' }, {
    group = state.group,
    once = true,
    callback = close_window,
  })

  vim.defer_fn(function()
    if state.win ~= win or not vim.api.nvim_win_is_valid(win) then
      return
    end

    vim.cmd('redraw')
    local pos = vim.api.nvim_win_get_position(win)
    local row = pos[1] + 1
    local col = pos[2] + 1
    show_iterm_image(path, row, col, width, height)
  end, 60)
end

local function show_chafa(path)
  local chafa = vim.fn.exepath('chafa')
  if chafa == '' then
    vim.notify('Chafa is required for terminal image previews.', vim.log.levels.ERROR)
    return
  end

  local width, height = fit_size(path)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'none',
    focusable = false,
  })

  state.win = win

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].cursorline = false
  vim.wo[win].winblend = 0

  vim.api.nvim_win_call(win, function()
    vim.fn.termopen({
      chafa,
      '--format=symbols',
      '--size=' .. width .. 'x' .. height,
      '--symbols=block+border',
      '--colors=full',
      '--animate=off',
      '--relative=off',
      path,
    }, {
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            close_window()
            vim.notify('Unable to render image preview with Chafa.', vim.log.levels.ERROR)
          end)
        end
      end,
    })
  end)

  vim.api.nvim_clear_autocmds({ group = state.group })
  vim.api.nvim_create_autocmd({ 'BufLeave', 'CursorMoved', 'InsertEnter', 'WinScrolled', 'VimResized' }, {
    group = state.group,
    once = true,
    callback = close_window,
  })
end

local function show_snacks(path)
  local ok, image = pcall(require, 'snacks.image')
  if not ok or not image.supports(path) then
    return false
  end

  image.hover()
  return true
end

local function close_snacks()
  local ok, image = pcall(require, 'snacks.image')
  if ok and image.doc and image.doc.hover_close then
    pcall(image.doc.hover_close)
  end
end

local function use_chafa()
  return vim.g.markdown_image_preview_backend == 'chafa'
end

function M.close()
  close_snacks()
  close_window()
end

function M.show()
  M.close()

  local src = image_src_at_cursor()
  local path, err = normalize_src(src)
  if not path then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify('Image not found: ' .. path, vim.log.levels.ERROR)
    return
  end

  if show_snacks(path) then
    return
  end

  if use_chafa() then
    show_chafa(path)
  else
    show_iterm(path)
  end
end

return M
