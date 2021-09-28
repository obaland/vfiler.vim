local core = require 'vfiler/core'
local vim = require "vfiler/vim"
local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'

local Context = {}
Context.__index = Context

local function to_index(lnum)
  -- correct the amount of the top path line
  return lnum - 1
end

function Context.new(configs)
  return setmetatable({
      items = {},
      path = '',
      visible_hidden_files = false,
      configs = core.deepcopy(configs),
    }, Context)
end

function Context:get_item(lnum)
  return self.items[to_index(lnum)]
end

function Context:close_directory(lnum)
  local item = self:get_item(lnum)
  if not item then
    return
  end
  local start_pos, end_pos
  if item.isdirectory and item.opened then
    start_pos = to_index(lnum) + 1
    end_pos = 0
    for pos = start_pos, #self.items do
      if item.level >= self.items[pos].level then
        end_pos = pos - 1
        break
      end
    end
  else
    -- find start position
    start_pos = 0
    for pos = to_index(lnum) - 1, 1, -1 do
      if item.level < self.items[pos] then
        start_pos = pos + 1
        break
      end
    end
    -- find end position
    end_pos = 0
    for pos = to_index(lnum) + 1, #self.items do
      if item.level < self.items[pos] then
        end_pos = pos - 1
        break
      end
    end
  end

  item.opened = false
  if start_pos >= end_pos then
    return
  end

end

function Context:open_directory(lnum)
  local item = self:get_item(lnum)
  if (not (item and item.isdirectory)) or item.opened then
    return
  end
  local pos = to_index(lnum) + 1
  for new_item in self:_create_items(item.path, item.level + 1) do
    table.insert(self.items, pos, new_item)
    pos = pos + 1
  end
  item.opened = true
end

function Context:switch(path)
  self.items = {}
  for item in self:_create_items(path, 0) do
    table.insert(self.items, item)
  end
  self.path = path
end

function Context:_create_items(path, level)
  path = path .. (self.visible_hidden_files and '/.*' or '/*')
  local paths = vim.fn.glob(path, 1, 1)
  local index = 0

  return function()
    local item = nil
    index = index + 1
    if paths[index] then
      local normalized_path = core.normalized_path(paths[index])
      local ftype = vim.fn.getftype(normalized_path)
      if ftype == 'dir' then
        item = Directory.new(normalized_path, level, false)
      elseif ftype == 'file' then
        item = File.new(normalized_path, level, false)
      elseif ftype == 'link' then
        if vim.fn.isdirectory(normalized_path) then
          item = Directory.new(normalized_path, 0, true)
        else
          item = File.new(normalized_path, level, true)
        end
      else
        core.warning('Unknown file type. (' .. ftype .. ')')
      end
    end
    return item
  end
end

return Context
