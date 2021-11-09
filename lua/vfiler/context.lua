local core = require 'vfiler/core'

local Directory = require 'vfiler/items/directory'

local function walk_expanded(rpaths, root_path, dir)
  if not dir.children then
    return
  end
  local expanded = false
  for _, child in ipairs(dir.children) do
    if child.isdirectory and child.children then
      walk_expanded(rpaths, root_path, child)
      expanded = true
    end
  end
  if not expanded then
    local path = dir.path:sub(#root_path + 1)
    if #path > 0 then
      table.insert(rpaths, path)
    end
  end
end

------------------------------------------------------------------------------
-- Store class

local Store = {}
Store.__index = Store

function Store.new()
  return setmetatable({
    _drives = {},
    _dirpaths = {},
  }, Store)
end

function Store:save(root, path)
  local drive = root:root()
  self._drives[drive] = root.path

  local rpaths = {}
  walk_expanded(rpaths, root.path, root)
  self._dirpaths[root.path] = {
    path = path,
    expanded_rpaths = rpaths,
  }
end

function Store:restore_path(dirpath)
  local stored = self._dirpaths[dirpath]
  if not stored then
    return nil
  end
  return stored.path, stored.expanded_rpaths
end

function Store:restore_dirpath(drive)
  local dirpath = self._drives[drive]
  if not dirpath then
    return nil
  end
  return dirpath
end

------------------------------------------------------------------------------
-- Context class

local Context = {}
Context.__index = Context

function Context.new(options)
  return setmetatable({
    clipboard = nil,
    extension = nil,
    root = nil,
    show_hidden_files = options.show_hidden_files,
    sort_type = options.sort,
    _store = Store.new(),
  }, Context)
end

function Context:save(path)
  if not self.root then
    return
  end
  self._store:save(self.root, path)
end

function Context:change_sort(type)
  if self.sort_type == type then
    return
  end
  self.root:sort(type, true)
  self.sort_type = type
end

-- @param path string
function Context:switch(dirpath, restore)
  self.root = Directory.new(dirpath, false, self.sort_type)
  self.root:open()

  local path, expanded_rpaths = self._store:restore_path(dirpath)
  if path and restore then
    for _, rpath in ipairs(expanded_rpaths) do
      self.root:expand(rpath)
    end
    return path
  end
  return self.root.path
end

function Context:switch_drive(drive, restore)
  local dirpath = self._store:restore_dirpath(drive)
  if not (restore and dirpath) then
    self.root = Directory.new(drive, false, self.sort_type)
    self.root:open()
    return self.root.path
  end
  return self:switch(dirpath, restore)
end

function Context:update()
  local rpaths = {}
  walk_expanded(rpaths, self.root.path, self.root)
  for _, rpath in ipairs(rpaths) do
    self.root:expand(rpath)
  end
end

return Context
