local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Item = {}
Item.__index = Item
Item.__eq = function(a, b)
  return a.name == b.name
end

function Item.new(name, path)
  return setmetatable({
    name = name,
    isdirectory = core.path.isdirectory(path),
    islink = vim.fn.getftype(path) == 'link',
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
