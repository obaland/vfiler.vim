local core = require('vfiler/libs/core')

local M = {}

local function get_ftype(ftype)
  local type
  if
    ftype == 'dir'
    or ftype == 'linkd'
    or ftype == 'junction'
    or ftype == 'reparse'
  then
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

function M.scandir(dirpath, callback)
  local dicts = vim.fn.readdirex(dirpath)
  for dict in dicts() do
    local path = core.path.join(dirpath, dict.name)
    local type, link = get_ftype(dict.type)
    if type and callback then
      callback({
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

return M
