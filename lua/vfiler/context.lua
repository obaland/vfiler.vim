local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Directory = require 'vfiler/items/directory'

local function walk_expanded(rpaths, root_path, dir)
  if not dir.children then
    return
  end

  local path = dir.path:sub(#root_path)
  if not rpaths[path] then
    rpaths[path] = {}
  end
  local attribute = rpaths[path]

  for _, child in ipairs(dir.children) do
    if child.isdirectory and child.children then
      walk_expanded(rpaths, root_path, child)
    end
    if child.selected then
      attribute[child.name] = {
        selected = true
      }
    end
  end
end

local function expand(names, dir)
  local name = table.remove(names, 1)
  for _, child in ipairs(dir.children) do
    if child.name == name then
      if not child.children then
        child:open()
      end
      if #names == 0 then
        return child
      else
        return expand(names, child)
      end
    end
  end
  return dir
end

------------------------------------------------------------------------------
-- Snapshot class

local Snapshot = {}
Snapshot.__index = Snapshot

function Snapshot.new()
  return setmetatable({
    _drives = {},
    _dirpaths = {},
  }, Snapshot)
end

function Snapshot:copy(snapshot)
  self._drives = core.table.copy(snapshot._drives)
  self._dirpaths = core.table.copy(snapshot._dirpaths)
end

function Snapshot:save(root, path)
  local drive = core.path.root(root.path)
  self._drives[drive] = root.path

  local rpaths = {}
  walk_expanded(rpaths, root.path, root)

  self._dirpaths[root.path] = {
    path = path,
    expanded_rpaths = rpaths,
  }
end

function Snapshot:load(root)
  local dirpath = self._dirpaths[root.path]
  if not dirpath then
    return root.path
  end

  for rpath, attributes in pairs(dirpath.expanded_rpaths) do
    -- expand
    local dir = root
    local names = core.string.split(rpath, '/')
    if #names > 0 then
      dir = expand(names, root)
    end

    -- restore attribute
    for _, child in ipairs(dir.children) do
      local attribute = attributes[child.name]
      if attribute then
        child.selected = attribute.selected
      end
    end
  end
  return dirpath.path
end

function Snapshot:load_dirpath(drive)
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
    _snapshot = Snapshot.new(),
  }, Context)
end

--- Clear the internal data
function Context:clear()
  self._root = nil
  self._snapshot = Snapshot.new()
end

--- Save the path in the current context
---@param path string
function Context:save(path)
  if not self.root then
    return
  end
  self._snapshot:save(self.root, path)
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
  self._snapshot:copy(context._snapshot)
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
  return self._snapshot:load(self.root)
end

--- Switch the context to the specified drive path
---@param drive string
function Context:switch_drive(drive)
  local dirpath = self._snapshot:load_dirpath(drive)
  if not dirpath then
    dirpath = drive
  end
  return self:switch(dirpath)
end

--- Synchronize with other context
---@param context table
function Context:sync(context)
  self._snapshot:save(context.root, context.root.path)
  self:switch(context.root.path)
end

return Context
