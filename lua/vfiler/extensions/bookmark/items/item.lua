local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Item = {}
Item.__index = Item

function Item.new(name, path)
  return setmetatable({
    name = name,
    is_directory = core.path.is_directory(path),
    is_link = vim.fn.getftype(path) == 'link',
    level = 2,
    parent = nil,
    path = path,
  }, Item)
end

function Item:delete()
  local parent = self.parent
  if not parent then
    return
  end
  for i, child in ipairs(parent.children) do
    if child.name == self.name then
      table.remove(parent.children, i)
      return
    end
  end
end

return Item
