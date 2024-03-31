local fs = require('vfiler/libs/filesystem')

local Item = {}
Item.__index = Item

function Item.new(name, path)
  local fstat = fs.stat(path)
  return setmetatable({
    name = name,
    level = 1,
    parent = nil,
    path = path,
    link = fstat and fstat.link or false,
    type = fstat and fstat.type or 'unknown',
  }, Item)
end

function Item.from_dict(dict)
  return Item.new(dict.name, dict.path)
end

function Item:delete()
  local parent = self.parent
  if not parent then
    return
  end
  for i, child in ipairs(parent.children) do
    if (child.type == self.type) and (child.name == self.name) then
      table.remove(parent.children, i)
      return
    end
  end
end

function Item:to_dict()
  return { name = self.name, path = self.path }
end

return Item
