local core = require 'vfiler/core'
local sort = require 'vfiler/sort'

local Directory = require 'vfiler/items/directory'

local Context = {}
Context.__index = Context

local function sort_items(items, compare)
  table.sort(items, compare)
  for _, item in ipairs(items) do
    if item.children then
      sort_items(item.children, compare)
    end
  end
end

function Context.new(configs)
  return setmetatable({
      clipboard = nil,
      extension = nil,
      root = nil,
      show_hidden_files = configs.show_hidden_files,
      sort = configs.sort,
    }, Context)
end

function Context:change_sort(type)
  if self.sort == type then
    return
  end
  self.root:sort(type, true)
  self.sort = type
end

-- @param path string
function Context:switch(path)
  self.root = Directory.new(core.normalized_path(path), false)
  self.root:open(self.sort)
end

function Context:update()
  self:switch(self.path)
end

return Context
