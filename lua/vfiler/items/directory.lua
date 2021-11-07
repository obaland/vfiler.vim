local core = require 'vfiler/core'
local sort = require 'vfiler/sort'
local vim = require 'vfiler/vim'

local File = require 'vfiler/items/file'

local Directory = {}

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
  self._sort = sort_type
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
  local src = core.string.shellescape(self.path)
  local dest = core.string.shellescape(destpath)
  if self.islink then
    core.file.copy(src, dest)
  else
    core.dir.copy(src, dest)
  end

  if not core.path.exists(destpath) then
    return nil
  end
  return Directory.new(destpath, self.islink, self._sort)
end

function Directory:move(destpath)
  if self:_move(destpath) then
    return Directory.new(destpath, self.islink, self._sort)
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

  self._sort = type
  self._sort_compare = sort.get(type)
  table.sort(self.children, self._sort_compare)

  if not recursive then
    return
  end

  -- sort recursive
  for _, child in ipairs(self.children) do
    if child.isdirectory then
      child:sort(type)
    end
  end
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

function Directory:_ls()
  local paths = vim.from_vimlist(
    vim.fn.glob(core.path.join(self.path, '/*'), 1, 1)
    )
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
    index = index + 1
    if not paths[index] then
      return nil
    end

    local filepath = paths[index]
    local ftype = vim.fn.getftype(filepath)
    local item = nil

    if ftype == 'dir' then
      item = Directory.new(filepath, false, self._sort)
    elseif ftype == 'file' then
      item = File.new(filepath, false)
    elseif ftype == 'link' then
      if core.path.isdirectory(filepath) then
        item = Directory.new(filepath, true, self._sort)
      else
        item = File.new(filepath, true)
      end
    else
      core.message.warning('Unknown file type. (%s)', ftype)
    end
    item.parent = self
    return item
  end
end

return Directory
