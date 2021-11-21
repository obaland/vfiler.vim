local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

function Item.new(filepath, islink)
  local size = vim.fn.getfsize(filepath)
  local time = vim.fn.getftime(filepath)
  if size < 0 or time < 0 then
    core.message.error('Failed - Invalid path "%s"', filepath)
    return nil
  end

  return setmetatable({
    isdirectory = core.path.isdirectory(filepath),
    islink = islink,
    level = 0,
    name = vim.fn.fnamemodify(filepath, ':t'),
    parent = nil,
    path = core.path.normalize(filepath),
    selected = false,
    size = size,
    time = time,
    mode = vim.fn.getfperm(filepath)
  }, Item)
end

function Item:delete()
  if vim.fn.delete(self.path, 'rf') < 0 then
    core.message.error('"%s" Cannot delete.', self.name)
    return false
  end
  self:_become_orphan()
  return true
end

function Item:rename(name)
  local newpath = core.path.join(self.parent.path, name)
  local result, message, code = os.rename(self.path, newpath)
  if not result then
    core.message.error('%s (code:%d)', message, code)
    return false
  end
  self.name = name
  self.path = newpath
  return true
end

--- Remove from parent tree
function Item:_become_orphan()
  if not self.parent then
    return
  end

  local children = self.parent.children
  for i, child in ipairs(children) do
    if child.path == self.path then
      table.remove(children, i)
      break
    end
  end
end

function Item:_move(destpath)
  core.file.move(self.path, destpath)
  if not core.path.exists(destpath) and core.path.exists(self.path) then
    return false
  end
  self:_become_orphan()
  return true
end

return Item
