local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Item = require('vfiler/extensions/bookmark/items/item')

local Category = {}
Category.__index = Category

local function compare(item1, item2)
  local is_category1 = item1.type == 'category'
  local is_category2 = item2.type == 'category'
  if is_category1 and not is_category2 then
    return true
  elseif not is_category1 and is_category2 then
    return false
  end
  return core.string.compare(item1.name, item2.name)
end

function Category.new_root()
  return Category.new('', 1)
end

function Category.new(name, level)
  return setmetatable({
    children = {},
    name = name,
    level = level or 1,
    opened = true,
    parent = nil,
    type = 'category',
  }, Category)
end

function Category.from_dict(dict, level)
  local category = Category.new(dict.name, level)
  for _, item in ipairs(dict.items) do
    category:add(Item.from_dict(item))
  end
  return category
end

function Category.from_json(json)
  local document = vim.fn.json_decode(json)
  if not document.bookmarks then
    return nil
  end
  local root = Category.new_root()
  for _, element in ipairs(document.bookmarks) do
    if element.items then
      -- Category
      root:add(Category.from_dict(element, root.level + 1))
    else
      -- Item
      root:add(Item.from_dict(element))
    end
  end
  return root
end

function Category:add(item)
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, item)
  table.sort(self.children, compare)
end

function Category:delete()
  local parent = self.parent
  if not parent then
    return
  end
  for i, child in ipairs(parent.children) do
    if child.type == 'category' and child.name == self.name then
      table.remove(parent.children, i)
      return
    end
  end
end

function Category:find_item(name)
  for _, child in ipairs(self.children) do
    if child.type ~= 'category' and child.name == name then
      return child
    end
  end
  return nil
end

function Category:find_category(name)
  for _, child in ipairs(self.children) do
    if child.type == 'category' and child.name == name then
      return child
    end
  end
  return nil
end

function Category:open()
  self.opened = true
end

function Category:close()
  self.opened = false
end

function Category:to_dict()
  local dict = { name = self.name }
  dict.items = {}
  for _, item in ipairs(self.children) do
    table.insert(dict.items, item:to_dict())
  end
  return dict
end

function Category:to_json()
  local document = { bookmarks = {} }
  for _, item in ipairs(self.children) do
    table.insert(document.bookmarks, item:to_dict())
  end
  return vim.fn.json_encode(document)
end

return Category
