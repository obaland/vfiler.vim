local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Category = {}
Category.__index = Category

function Category.new(name)
  return setmetatable({
    children = {},
    name = name,
    iscategory = true,
  }, Category)
end

function Category:add(item)
  table.insert(self.children, item)
end

function Category:find_category(name)
  for _, child in ipairs(self.children) do
    if child.iscategory and child.name == name then
      return child
    end
  end
  return nil
end

function Category:to_json(path)
  local document = vim.to_vimdict({
    bookmarks = vim.to_vimlist(),
  })
  for _, category in ipairs(self.children) do
    local category_dict = vim.to_vimdict({
      name = category.name,
    })
    local items = vim.to_vimlist()
    for _, item in ipairs(category.children) do
      local item_dict = vim.to_vimdict({
        name = item.name,
        path = item.path,
      })
      table.insert(items, item_dict)
    end
    if #items > 0 then
      category_dict.items = items
    end
    table.insert(document.bookmarks, category_dict)
  end
  return vim.fn.json_encode(document)
end

return Category
