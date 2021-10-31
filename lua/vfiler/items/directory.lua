local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local File = require 'vfiler/items/file'

local Directory = {}

function Directory.create(path)
  -- mkdir
  if vim.fn.mkdir(path) ~= 1 then
    return nil
  end
  return Directory.new(path, false)
end

function Directory.new(path, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(Directory, Item, path, islink)
  self.children = nil
  self.opened = false
  self.type = self.islink and 'L' or 'D'
  return self
end

function Directory:add(item, sort_type)
  if not self.children then
    self.children = {}
  end
  local compare = sort.get(sort_type)
  self:_add(item, compare)
end

function Directory:close()
  self.children = nil
  self.opened = false
end

function Directory:open(sort_type)
  local compare = sort.get(sort_type)
  self.children = {}
  for item in self:_ls() do
    self:_add(item, compare)
  end
  self.opened = true
end

function Directory:sort(type)
  if not self.children or #self.children <= 1 then
    return
  end

  local compare = sort.get(type)
  table.sort(self.children, compare)

  -- sort recursive
  for _, child in ipairs(self.children) do
    if child.isdirectory then
      child:sort(type)
    end
  end
end

function Directory:_add(item, compare)
  local pos = #self.children + 1
  for i, child in ipairs(self.children) do
    if compare(item, child) then
      pos = i
      break
    end
  end
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, pos, item)
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

  return function()
    index = index + 1
    if not paths[index] then
      return nil
    end

    local path = paths[index]
    local ftype = vim.fn.getftype(path)
    local item = nil

    if ftype == 'dir' then
      item = Directory.new(path, false)
    elseif ftype == 'file' then
      item = File.new(path, false)
    elseif ftype == 'link' then
      if vim.fn.isdirectory(path) then
        item = Directory.new(path, true)
      else
        item = File.new(path, true)
      end
    else
      core.warning('Unknown file type. (' .. ftype .. ')')
    end
    item.parent = self
    return item
  end
end

return Directory
