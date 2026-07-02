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

local python_root_markers = {
  'pyrightconfig.json',
  'pyproject.toml',
  'setup.py',
  'setup.cfg',
  'requirements.txt',
  'Pipfile',
  '.git',
}

local package_sections = {
  'dependencies',
  'devDependencies',
  'peerDependencies',
  'optionalDependencies',
}

local package_cache = {}
local node_bin_cache = {}

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

local function package_json(bufnr)
  return vim.fs.find('package.json', { upward = true, path = buf_dir(bufnr) })[1]
end

local function read_package(path)
  if package_cache[path] ~= nil then
    return package_cache[path] or nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    package_cache[path] = false
    return nil
  end

  local decoded_ok, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not decoded_ok or type(data) ~= 'table' then
    package_cache[path] = false
    return nil
  end

  package_cache[path] = data
  return data
end

local function has_package_dependency(bufnr, names)
  local path = package_json(bufnr)
  if not path then
    return false
  end

  local data = read_package(path)
  if not data then
    return false
  end

  for _, section in ipairs(package_sections) do
    local dependencies = data[section]
    if type(dependencies) == 'table' then
      for _, name in ipairs(names) do
        if dependencies[name] ~= nil then
          return true
        end
      end
    end
  end

  return false
end

function M.is_frontend_filetype(filetype)
  return frontend_filetypes[filetype] == true
end

function M.python_root(bufnr)
  return root_file(bufnr, python_root_markers)
end

function M.python_path_for_root(root)
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= '' then
    return vim.env.VIRTUAL_ENV .. '/bin/python'
  end

  root = root or vim.uv.cwd()
  for _, dirname in ipairs { '.venv', 'venv' } do
    local python = root .. '/' .. dirname .. '/bin/python'
    if vim.fn.executable(python) == 1 then
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

  if has_package_dependency(bufnr, { 'oxfmt' }) then
    return vim.fs.dirname(package_json(bufnr))
  end

  return nil
end

function M.oxlint_root(bufnr)
  local root = root_file(bufnr, oxlint_markers)
  if root then
    return root
  end

  if has_package_dependency(bufnr, { 'oxlint' }) then
    return vim.fs.dirname(package_json(bufnr))
  end

  return nil
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

  node_bin_cache[cache_key] = found or false
  return found
end

return M
