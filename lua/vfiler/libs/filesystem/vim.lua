local core = require('vfiler/libs/core')

local M = {}

local function get_ftype(ftype)
  local type
  if ftype == 'dir' or ftype == 'linkd' or ftype == 'junction' then
    type = 'directory'
  elseif ftype == 'link' then
    type = 'file'
  else
    type = ftype
  end
  return type, (ftype == 'link' or ftype == 'linkd' or ftype == 'junction')
end

function M.stat(path)
  local type, link = get_ftype(vim.fn.getftype(path))
  if not type then
    return nil
  end
  return {
    path = core.path.normalize(path),
    name = core.path.name(path),
    size = vim.fn.getfsize(path),
    time = vim.fn.getftime(path),
    mode = vim.fn.getfperm(path),
    type = type,
    link = link,
  }
end

function M.scandir(dirpath)
  local dicts = vim.fn.readdirex(dirpath)
  local function scandir()
    for dict in dicts() do
      local path = core.path.join(dirpath, dict.name)
      local type, link = get_ftype(dict.type)
      if type then
        coroutine.yield({
          path = type == 'directory' and path .. '/' or path,
          name = dict.name,
          size = dict.size,
          time = dict.time,
          mode = dict.perm,
          type = type,
          link = link,
        })
      end
    end
  end
  return coroutine.wrap(scandir)
end

return M
