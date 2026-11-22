local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')

local File = require('vfiler/items/file')
local Item = require('vfiler/items/item')

local Directory = setmetatable({}, { __index = Item })
local directory_metatable = { __index = Directory }

local function new_item(stat)
  local item
  if stat.type == 'directory' then
    item = Directory.new(stat)
  elseif
    stat.type == 'file'
    or stat.type == 'link'
    or stat.type == 'fifo'
    or stat.type == 'socket'
  then
    item = File.new(stat)
  else
    core.message.warning('Unknown "%s" file type. (%s)', stat.type, stat.path)
  end
  return item
end

function Directory.create(dirpath)
  if not fs.create_directory(dirpath) then
    return nil
  end
  local stat = fs.stat(dirpath)
  if not stat then
    return nil
  end
  return Directory.new(stat)
end

function Directory.new(stat)
  local self = Item.new(stat, directory_metatable)
  self.children = nil
  self.child_directories = nil
  self.opened = false
  return self
end

function Directory:add(item)
  if not self.children then
    self.children = {}
    self.child_directories = {}
  end
  self:_remove(item)
  self:_add(item)
end

function Directory:remove(item)
  self:_remove(item)
end

function Directory:close()
  self.children = nil
  self.child_directories = nil
  self.opened = false
end

function Directory:copy(destpath)
  if not fs.copy_directory(self:_get_path(), destpath) then
    return nil
  end
  local stat = fs.stat(destpath)
  if not stat then
    return nil
  end
  return Directory.new(stat)
end

function Directory:create_directory(name)
  local dirpath = core.path.join(self.path, name)
  local directory = Directory.create(dirpath)
  if not core.path.is_directory(dirpath) then
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
    return Directory.new(fs.stat(destpath))
  end
  return nil
end

function Directory:open(recursive)
  local child_directories = self.child_directories or {}
  self:_open(recursive, child_directories)
end

function Directory:_add(item)
  item.parent = self
  item.level = self.level + 1
  table.insert(self.children, item)
  if item.type == 'directory' then
    self.child_directories[item.name] = item
  end
end

function Directory:_remove(item)
  local pos = nil
  for i, child in ipairs(self.children) do
    if (child.name == item.name) and (child.type == item.type) then
      pos = i
      break
    end
  end
  if pos then
    table.remove(self.children, pos)
    if item.type == 'directory' then
      self.child_directories[item.name] = nil
    end
  end
end

function Directory:_open(recursive, child_directories, ancestors)
  -- Prevent recursive cycles by tracking resolved paths on the current branch.
  -- Remove each path after visiting its children so sibling links to the same
  -- directory can still be expanded.
  local realpath
  if recursive then
    ancestors = ancestors or {}
    realpath = core.path.normalize(vim.fn.resolve(self.path))
    if core.is_windows then
      realpath = realpath:lower()
    end
    if ancestors[realpath] then
      return
    end
    ancestors[realpath] = true
  end

  self.children = {}
  self.child_directories = {}
  local children = {}
  fs.scandir(self.path, function(stat)
    local item = new_item(stat)
    if item then
      self:_add(item)
      if item.type == 'directory' then
        local old_dir_item = child_directories[item.name]
        if recursive or (old_dir_item and old_dir_item.opened) then
          table.insert(children, { item, old_dir_item })
        end
      end
    end
  end)

  for _, child in ipairs(children) do
    local item = child[1]
    local old_item = child[2]
    item:_open(
      recursive,
      (old_item and old_item.child_directories) or {},
      ancestors
    )
  end

  if recursive then
    ancestors[realpath] = nil
  end
  self.opened = true
end

return Directory
