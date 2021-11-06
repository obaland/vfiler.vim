local core = require 'vfiler/core'

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

function Context.new(options)
  return setmetatable({
      clipboard = nil,
      extension = nil,
      root = nil,
      show_hidden_files = options.show_hidden_files,
      sort = options.sort,
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
function Context:switch(dirpath)
  self.root = Directory.new(dirpath, false, self.sort)
  self.root:open()
end

function Context:update()
  self:switch(self.path)
end

return Context
