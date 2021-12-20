local Item = {}
Item.__index = Item

function Item.new(name, item)
  return setmetatable({
    name = name,
    isdirectory = item.isdirectory,
    islink = item.islink,
    path = item.path,
  }, Item)
end

return Item
