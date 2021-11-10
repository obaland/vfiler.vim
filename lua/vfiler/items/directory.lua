local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local File = require 'vfiler/items/file'

local Directory = {}

local function create_item(path, sort_type)
  local ftype = vim.fn.getftype(path)
  if #ftype == 0 then
    return nil
  end

  local item = nil
  if ftype == 'dir' then
    item = Directory.new(path, false, sort_type)
  elseif ftype == 'file' then
    item = File.new(path, false)
  elseif ftype == 'link' then
    if core.path.isdirectory(path) then
      item = Directory.new(path, true, sort_type)
    else
      item = File.new(path, true)
    end
  else
    core.message.warning('Unknown "%s" file type. (%s)', ftype, path)
  end
  return item
end

function Directory.create(dirpath, sort_type)
  -- mkdir
  if vim.fn.mkdir(dirpath) ~= 1 then
    return nil
  end
  return Directory.new(dirpath, false, sort_type)
end

function Directory.new(dirpath, islink, sort_type)
  local Item = require('vfiler/items/item')
  local self = core.inherit(Directory, Item, dirpath, islink)
  self.children = nil
  self.opened = false
  self.type = self.islink and 'L' or 'D'
  self.sort_type = sort_type
  self._sort_compare = sort.get(sort_type)
  return self
end

function Directory:add(item)
  if not self.children then
    self.children = {}
  end
  self:_add(item)
end

function Directory:close()
  self.children = nil
  self.opened = false
end

function Directory:copy(destpath)
  if self.islink then
    core.file.copy(self.path, destpath)
  else
    core.dir.copy(self.path, destpath)
  end

  if not core.path.exists(destpath) then
    return nil
  end
  return Directory.new(destpath, self.islink, self.sort_type)
end

function Directory:expand(relative_path)
  local names = core.string.split(relative_path, '/')
  return self:_expand(names)
end

function Directory:move(destpath)
  if self:_move(destpath) then
    return Directory.new(destpath, self.islink, self.sort_type)
  end
  return nil
end

function Directory:open()
  self.children = {}
  for item in self:_ls() do
    self:_add(item)
  end
  self.opened = true
end

function Directory:sort(type, recursive)
  if not self.children or #self.children <= 1 then
    return
  end

  self.sort_type = type
  self._sort_compare = sort.get(type)
  table.sort(self.children, self._sort_compare)

  if not recursive then
    return
  end

  -- sort recursive
  for _, child in ipairs(self.children) do
    if child.isdirectory then
      child:sort(type, recursive)
    end
  end
end

function Directory:walk(hidden)
  local items = {}
  self:_walk(items, hidden)
  return items
end

function Directory:_add(item)
  local pos = #self.children + 1
  for i, child in ipairs(self.children) do
    if self._sort_compare(item, child) then
      pos = i
      break
    end
  end
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, pos, item)
end

function Directory:_expand(names)
  if not self.children then
    self:open()
  end
  local name = table.remove(names, 1)
  for _, child in ipairs(self.children) do
    if child.name == name then
      if #names == 0 then
        child:open()
        return
      end
      child:_expand(names)
    end
  end
end

function Directory:_ls()
  local items = {}

  local paths = vim.from_vimlist(
    vim.fn.glob(core.path.join(self.path, '/*'), 1, 1)
    )
  for _, path in ipairs(paths) do
    local item = create_item(path, self.sort_type)
    if item then
      table.insert(items, item)
    end
  end

  local dotpaths = vim.from_vimlist(
    vim.fn.glob(core.path.join(self.path, '/.*'), 1, 1)
    )
  for _, dotpath in ipairs(dotpaths) do
    local dotfile = vim.fn.fnamemodify(dotpath, ':t')
    if not (dotfile == '.' or dotfile == '..') then
      local item = create_item(dotpath, self.sort_type)
      if item then
        table.insert(items, item)
      end
    end
  end

  local index = 0

  return function()
    index = index + 1
    return items[index]
  end
end

function Directory:_walk(items, hidden)
  if not self.children then
    return
  end
  for _, child in ipairs(self.children) do
    local hidden_file = child.name:sub(1, 1) == '.'
    if hidden or not hidden_file then
      table.insert(items, child)
      if child.isdirectory then
        child:_walk(items)
      end
    end
  end
end

return Directory
