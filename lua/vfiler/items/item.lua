local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

function Item.new(path, islink)
  local size = vim.fn.getfsize(path)
  local time = vim.fn.getftime(path)
  if size < 0 or time < 0 then
    core.error(('Failed - Invalid path (%s)'):format(path))
    return nil
  end

  return setmetatable({
      isdirectory = vim.fn.isdirectory(path) == 1,
      islink = islink,
      level = 0,
      name = vim.fn.fnamemodify(path, ':t'),
      parent = nil,
      path = core.normalized_path(path),
      selected = false,
      size = size,
      time = time,
      mode = vim.fn.getfperm(path)
    }, Item)
end

function Item:delete()
  if vim.fn.delete(self.path, 'rf') < 0 then
    core.error(([["%s" Cannot delete]]):format(self.name))
    return false
  end

  -- delete from item tree
  if not self.parent then
    return true
  end

  local children = self.parent.children
  for i, child in ipairs(children) do
    if child.path == self.path then
      table.remove(children, i)
      break
    end
  end
  return true
end

function Item:rename(name)
  local newpath = self.parent.path .. '/' .. name
  local result, message, code = os.rename(self.path, newpath)
  if not result then
    core.error(('%s (code:%d)'):format(message, code))
    return false
  end
  self.name = name
  self.path = newpath
  return true
end

return Item
