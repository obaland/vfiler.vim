local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require "vfiler/vim"

local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'

local Context = {}
Context.__index = Context

function Context.new(bufnr, configs)
  return setmetatable({
      bufnr = bufnr,
      configs = configs,
      extension = nil,
      items = {},
      path = '',
      show_hidden_files = false,
      sort = 'name',
    }, Context)
end

function Context:get_item(lnum)
  return self.items[lnum]
end

function Context:close_directory(lnum)
  local target = self.items[lnum]
  if not (target and (target.opened or target.level > 1)) then
    return nil
  end
  local target_pos = lnum
  local start_pos, end_pos
  if target.isdirectory and target.opened then
    start_pos = target_pos + 1
    end_pos = 0
    for pos = start_pos, #self.items do
      if target.level >= self.items[pos].level then
        end_pos = pos - 1
        break
      end
    end
  else
    -- find start position
    start_pos = 0
    for pos = lnum - 1, 1, -1 do
      if target.level > self.items[pos].level then
        target_pos = pos
        start_pos = pos + 1
        break
      end
    end
    -- find end position
    end_pos = #self.items
    for pos = lnum + 1, #self.items do
      if target.level > self.items[pos].level then
        end_pos = pos - 1
        break
      end
    end
  end

  self.items[target_pos].opened = false
  if (start_pos <= 0 or end_pos <= 0) or start_pos > end_pos then
    return nil
  end
  -- delete items
  for _ = 1, (end_pos - start_pos + 1) do
    table.remove(self.items, start_pos)
  end
  return target_pos
end

function Context:open_directory(lnum)
  local item = self:get_item(lnum)
  if (not (item and item.isdirectory)) or item.opened then
    return nil
  end

  -- create opened item list
  local compare = sort.compares[self.sort]
  local opened_items = {}
  for opened_item in self:_create_items(item.path, item.level + 1) do
    local pos = self:_search_insert_position(
      opened_items, opened_item, compare
      )
    table.insert(opened_items, pos, opened_item)
  end

  -- insert opened item
  for i, opened_item in ipairs(opened_items) do
    table.insert(self.items, lnum + i, opened_item)
  end
  item.opened = true
  return lnum
end

function Context:switch(path)
  -- create header item
  self.items = {}
  local compare = sort.compares[self.sort]
  for item in self:_create_items(path, 1) do
    local pos = self:_search_insert_position(self.items, item, compare)
    table.insert(self.items, pos, item)
  end
  -- add header item to top
  table.insert(self.items, 1, Directory.new(path, 0, false))
  self.path = path
end

function Context:_search_insert_position(items, target, compare)
  for i, item in ipairs(items) do
    if compare(target, item) then
      return i
    end
  end
  return #items + 1
end

function Context:_create_items(path, level)
  path = path .. (self.show_hidden_files and '/.*' or '/*')
  local paths = vim.fn.glob(path, 1, 1)
  local index = 0

  return function()
    index = index + 1
    if not paths[index] then
      return nil
    end

    local item = nil
    local normalized_path = core.normalized_path(paths[index])
    local ftype = vim.fn.getftype(normalized_path)
    if ftype == 'dir' then
      item = Directory.new(normalized_path, level, false)
    elseif ftype == 'file' then
      item = File.new(normalized_path, level, false)
    elseif ftype == 'link' then
      if vim.fn.isdirectory(normalized_path) then
        item = Directory.new(normalized_path, level, true)
      else
        item = File.new(normalized_path, level, true)
      end
    else
      core.warning('Unknown file type. (' .. ftype .. ')')
    end
    return item
  end
end

return Context
