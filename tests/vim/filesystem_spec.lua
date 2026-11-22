local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

assert(not core.is_nvim)

local root = core.path.normalize(vim.fn.tempname())
assert(vim.fn.mkdir(root, 'p') == 1)
local ok, err = xpcall(function()
  local directory = root .. '/child dir'
  local file = directory .. '/file name.txt'
  assert(vim.fn.mkdir(directory) == 1)
  assert(vim.fn.writefile(vim.list({ 'content' }), file) == 0)

  local function scan(path)
    local entries = {}
    fs.scandir(path, function(stat)
      entries[stat.name] = stat
    end)
    return entries
  end

  assert(scan(root)['child dir'].path == directory .. '/')
  for _, path in ipairs({ directory, directory .. '/' }) do
    local stat = assert(scan(path)['file name.txt'])
    assert(stat.path == file)
    assert(stat.type == 'file')
    assert(stat.size == vim.fn.getfsize(file))
  end
end, debug.traceback)
vim.fn.delete(root, 'rf')
assert(ok, err)
