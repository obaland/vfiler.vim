local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local File = require 'vfiler/items/file'

local Directory = {}

local function insert_position(items, target, compare)
  for i, item in ipairs(items) do
    if compare(target, item) then
      return i
    end
  end
  return #items + 1
end

local function sort_items(items, compare)
  table.sort(items, compare)
  for _, item in ipairs(items) do
    if item.children then
      sort_items(item.children, compare)
    end
  end
end

function Directory.new(path, level, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(Directory, Item, path, level, islink)
  self.children = nil
  self.opened = false
  self.type = self.islink and 'L' or 'D'
  return self
end

function Directory:close()
  self.children = nil
  self.opened = false
end

function Directory:open(sort_type)
  local compare = sort.compares[sort_type]
  if not compare then
    core.error(([[Invalid sort type "%s"]]):format(sort_type))
    return nil
  end

  self.children = {}
  for item in self:_ls() do
    local pos = insert_position(self.children, item, compare)
    table.insert(self.children, pos, item)
  end
  self.opened = true
end

function Directory:sort(type)
  local compare = sort.compares[type]
  if not compare then
    core.error(([[Invalid sort type "%s"]]):format(type))
    return nil
  end
  sort_items(self.children, compare)
end

function Directory:_ls()
  local paths = vim.fn.glob(self.path .. '/*', 1, 1)
  local dotpaths = vim.fn.glob(self.path .. '/.*', 1, 1)
  for _, dotpath in ipairs(dotpaths) do
    local dotfile = vim.fn.fnamemodify(dotpath, ':t')
    if not (dotfile == '.' or dotfile == '..') then
      table.insert(paths, dotpath)
    end
  end

  local index = 0
  local level = self.level + 1

  return function()
    index = index + 1
    if not paths[index] then
      return nil
    end

    local normalized = core.normalized_path(paths[index])
    local ftype = vim.fn.getftype(normalized)

    local item = nil
    if ftype == 'dir' then
      item = Directory.new(normalized, level, false)
    elseif ftype == 'file' then
      item = File.new(normalized, level, false)
    elseif ftype == 'link' then
      if vim.fn.isdirectory(normalized) then
        item = Directory.new(normalized, level, true)
      else
        item = File.new(normalized, level, true)
      end
    else
      core.warning('Unknown file type. (' .. ftype .. ')')
    end
    item.parent = self
    return item
  end
end

return Directory
