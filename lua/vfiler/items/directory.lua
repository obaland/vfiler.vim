local core = require('vfiler/core')
local vim = require('vfiler/vim')

local File = require('vfiler/items/file')

local Directory = {}

local function create_item(path)
  local ftype = vim.fn.getftype(path)
  if #ftype == 0 then
    return nil
  end

  local item = nil
  if ftype == 'dir' then
    item = Directory.new(path, false)
  elseif ftype == 'file' then
    item = File.new(path, false)
  elseif ftype == 'link' then
    if core.path.isdirectory(path) then
      item = Directory.new(path, true)
    else
      item = File.new(path, true)
    end
  else
    core.message.warning('Unknown "%s" file type. (%s)', ftype, path)
  end
  return item
end

function Directory.create(dirpath)
  if vim.fn.mkdir(dirpath) ~= 1 then
    return nil
  end
  return Directory.new(dirpath, false)
end

function Directory.new(dirpath, islink)
  local Item = require('vfiler/items/item')

  local self = core.inherit(Directory, Item, dirpath, islink)
  self.children = nil
  self.opened = false
  self.type = self.islink and 'L' or 'D'
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
  return Directory.new(destpath, self.islink)
end

function Directory:create_directory(name)
  local dirpath = core.path.join(self.path, name)
  local directory = Directory.create(dirpath)
  if not core.path.isdirectory(dirpath) then
    return nil
  end
  self:add(directory)
  return directory
end

function Directory:create_file(name)
  local filepath = core.path.join(self.path, name)
  local file = File.create(filepath)
  if not core.path.filereadable(filepath) then
    return nil
  end
  self:add(file)
  return file
end

function Directory:move(destpath)
  if self:_move(destpath) then
    return Directory.new(destpath, self.islink)
  end
  return nil
end

function Directory:open(recursive)
  self.children = {}
  for item in self:_ls() do
    self:_add(item)
    if recursive and item.isdirectory then
      item:open(recursive)
    end
  end
  self.opened = true
end

function Directory:_add(item)
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, item)
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

  local function _ls()
    for _, path in ipairs(paths) do
      local item = create_item(path)
      if item then
        coroutine.yield(item)
      end
    end
  end
  return coroutine.wrap(_ls)
end

function Directory:_remove(item)
  local pos = nil
  for i, child in ipairs(self.children) do
    if
      (child.name == item.name)
      and (child.isdirectory == item.isdirectory)
    then
      pos = i
      break
    end
  end
  if pos then
    table.remove(self.children, pos)
  end
end

return Directory
