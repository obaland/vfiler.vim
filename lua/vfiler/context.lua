local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

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

function Store:copy(store)
  self._drives = core.table.copy(store._drives)
  self._dirpaths = core.table.copy(store._dirpaths)
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

--- Create a context object
---@param options table
function Context.new(options)
  return setmetatable({
    auto_cd = options.auto_cd,
    clipboard = nil,
    extension = nil,
    root = nil,
    sort_type = options.sort,
    _store = Store.new(),
  }, Context)
end

--- Clear the internal data
function Context:clear()
  self._root = nil
  self._store = Store.new()
end

--- Save the path in the current context
---@param path string
function Context:save(path)
  if not self.root then
    return
  end
  self._store:save(self.root, path)
end

--- Change the sort type
---@param type string
function Context:change_sort(type)
  if self.sort_type == type then
    return
  end
  self.root:sort(type, true)
  self.sort_type = type
end

--- Duplicate another context
---@param context table
function Context:duplicate(context)
  self._store:copy(context._store)
  self:switch(context.root.path)
end

--- Get the parent directory path of the current context
function Context:parent_path()
  if self.root.parent then
    return self.root.parent.path
  end
  local path = self.root.path
  local mods = path:sub(#path, #path) == '/' and ':h:h' or ':h'
  return vim.fn.fnamemodify(path, mods)
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch(dirpath)
  -- perform auto cd
  if self.auto_cd then
    vim.command('silent lcd ' .. dirpath)
  end

  self.root = Directory.new(dirpath, false, self.sort_type)
  self.root:open()

  local path, expanded_rpaths = self._store:restore_path(dirpath)
  if path then
    for _, rpath in ipairs(expanded_rpaths) do
      self.root:expand(rpath)
    end
    return path
  end
  return self.root.path
end

--- Switch the context to the specified drive path
---@param drive string
function Context:switch_drive(drive)
  local dirpath = self._store:restore_dirpath(drive)
  if not dirpath then
    dirpath = drive
  end
  return self:switch(dirpath)
end

--- Update the current context
function Context:update()
  local rpaths = {}
  walk_expanded(rpaths, self.root.path, self.root)
  self.root = Directory.new(self.root.path, false, self.sort_type)
  self.root:open()
  for _, rpath in ipairs(rpaths) do
    self.root:expand(rpath)
  end
end

--- Synchronize with other context
---@param context table
function Context:sync(context)
  self._store:save(context.root, context.root.path)
  self:switch(context.root.path)
end

return Context
