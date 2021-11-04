local core = require 'vfiler/core'
local path = require 'vfiler/path'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

function Item.new(filepath, islink)
  local size = vim.fn.getfsize(filepath)
  local time = vim.fn.getftime(filepath)
  if size < 0 or time < 0 then
    core.error('Failed - Invalid path "%s"', filepath)
    return nil
  end

  return setmetatable({
      isdirectory = path.isdirectory(filepath),
      islink = islink,
      level = 0,
      name = vim.fn.fnamemodify(filepath, ':t'),
      parent = nil,
      path = path.normalize(filepath),
      selected = false,
      size = size,
      time = time,
      mode = vim.fn.getfperm(filepath)
    }, Item)
end

function Item:delete()
  if vim.fn.delete(self.path, 'rf') < 0 then
    core.error('"%s" Cannot delete.', self.name)
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
  local newpath = path.join(self.parent.path, name)
  local result, message, code = os.rename(self.path, newpath)
  if not result then
    core.error('%s (code:%d)', message, code)
    return false
  end
  self.name = name
  self.path = newpath
  return true
end

return Item
