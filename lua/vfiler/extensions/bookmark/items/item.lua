local fs = require('vfiler/libs/filesystem')

local Item = {}
Item.__index = Item

function Item.new(name, path)
  local fstat = fs.stat(path)
  return setmetatable({
    name = name,
    level = 2,
    parent = nil,
    path = path,
    link = fstat.link,
    type = fstat.type,
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
