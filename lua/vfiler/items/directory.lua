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
  self:_remove(item)
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

function Directory:walk()
  local function _walk(item)
    coroutine.yield(item)
    if item.children then
      for _, child in ipairs(item.children) do
        _walk(child)
      end
    end
  end
  return coroutine.wrap(function()
    _walk(self)
  end)
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
  local paths = vim.from_vimlist(
    vim.fn.glob(core.path.join(self.path, '/*'), 1, 1)
    )

  -- extend hidden paths
  local dotpaths = vim.from_vimlist(
    vim.fn.glob(core.path.join(self.path, '/.*'), 1, 1)
    )
  for _, dotpath in ipairs(dotpaths) do
    local dotfile = vim.fn.fnamemodify(dotpath, ':t')
    if not (dotfile == '.' or dotfile == '..') then
      table.insert(paths, dotpath)
    end
  end

  local index = 0

  return function()
    local item = nil
    repeat
      index = index + 1
      local path = paths[index]
      if not path then
        break
      end
      item = create_item(path, self.sort_type)
    until item
    return item
  end
end

function Directory:_remove(item)
  local pos = nil
  for i, child in ipairs(self.children) do
    if (child.name == item.name) and
       (child.isdirectory == item.isdirectory) then
       pos = i
       break
    end
  end
  if pos then
    table.remove(self.children, pos)
  end
end

return Directory
