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

local package_sections = {
  'dependencies',
  'devDependencies',
  'peerDependencies',
  'optionalDependencies',
}

local package_cache = {}

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

function M.oxfmt_root(bufnr)
  local root = root_file(bufnr, oxfmt_markers)
  if root then
    return root
  end

  if has_package_dependency(bufnr, { 'oxfmt' }) then
    return vim.fs.dirname(package_json(bufnr))
  end
end

function M.oxlint_root(bufnr)
  local root = root_file(bufnr, oxlint_markers)
  if root then
    return root
  end

  if has_package_dependency(bufnr, { 'oxlint' }) then
    return vim.fs.dirname(package_json(bufnr))
  end
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
  for _, node_modules in ipairs(vim.fs.find('node_modules', { upward = true, path = buf_dir(bufnr), limit = math.huge })) do
    local bin = node_modules .. '/.bin/' .. name
    if vim.fn.executable(bin) == 1 then
      return bin
    end
  end

  if vim.fn.executable(name) == 1 then
    return name
  end
end

return M
