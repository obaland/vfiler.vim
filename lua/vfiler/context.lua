local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Directory = require('vfiler/items/directory')

local function expand(root, attribute)
  for _, child in ipairs(root.children) do
    local opened = attribute.opened_attributes[child.name]
    if opened then
      child:open()
      expand(child, opened)
    end

    local selected = attribute.selected_names[child.name]
    if selected then
      child.selected = true
    end
  end
  return root
end

------------------------------------------------------------------------------
-- ItemAttribute class
------------------------------------------------------------------------------
local ItemAttribute = {}
ItemAttribute.__index = ItemAttribute

function ItemAttribute.copy(attribute)
  local root_attr = ItemAttribute.new(attribute.name)
  for name, attr in pairs(attribute.opened_attributes) do
    root_attr.opened_attributes[name] = ItemAttribute.copy(attr)
  end
  for name, selected in pairs(attribute.selected_names) do
    root_attr.selected_names[name] = selected
  end
  return root_attr
end

function ItemAttribute.parse(root)
  local root_attr = ItemAttribute.new(root.name)
  if not root.children then
    return root_attr
  end
  for _, child in ipairs(root.children) do
    if child.isdirectory and child.opened then
      root_attr.opened_attributes[child.name] = ItemAttribute.parse(child)
    end
    if child.selected then
      root_attr.selected_names[child.name] = true
    end
  end
  return root_attr
end

function ItemAttribute.new(name)
  return setmetatable({
    name = name,
    opened_attributes = {},
    selected_names = {},
  }, ItemAttribute)
end

------------------------------------------------------------------------------
-- Snapshot class
------------------------------------------------------------------------------

local Snapshot = {}
Snapshot.__index = Snapshot

function Snapshot.new()
  return setmetatable({
    _drives = {},
    _attributes = {},
  }, Snapshot)
end

function Snapshot:copy(snapshot)
  self._drives = core.table.copy(snapshot._drives)
  for path, attribute in pairs(self._attributes) do
    self._attributes[path] = {
      previus_path = attribute.previus_path,
      object = ItemAttribute.copy(attribute.object),
    }
  end
end

function Snapshot:save(root, path)
  local drive = core.path.root(root.path)
  self._drives[drive] = root.path
  self._attributes[root.path] = {
    previus_path = path,
    object = ItemAttribute.parse(root),
  }
end

function Snapshot:load(root)
  local attribute = self._attributes[root.path]
  if not attribute then
    return nil
  end
  expand(root, attribute.object)
  return attribute.previus_path
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
------------------------------------------------------------------------------

local Context = {}
Context.__index = Context

--- Create a context object
---@param configs table
function Context.new(configs)
  local self = setmetatable({}, Context)
  self:_initialize()
  self._events = core.table.copy(configs.events)
  self._mappings = core.table.copy(configs.mappings)
  self._snapshot = Snapshot.new()

  -- set options
  for key, value in pairs(configs.options) do
    -- skip ignore option
    if key == 'new' then
      goto continue
    end

    if self[key] then
      core.message.warning('Duplicate "%s" option.', key)
    end
    self[key] = value
    ::continue::
  end
  return self
end

function Context:_initialize()
  self.clipboard = nil
  self.extension = nil
  self.linked = nil
  self.root = nil
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
  if self.sort == type then
    return
  end
  self.root:sort(type, true)
  self.sort = type
end

--- Duplicate context
function Context:duplicate()
  local new = setmetatable({}, Context)
  new:_initialize()
  new:reset(self)
  new._snapshot:copy(self._snapshot)
  return new
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

--- Reset from another context
---@param context table
function Context:reset(context)
  self:cancel_all_jobs()
  self:_initialize()
  -- copy options
  for key, value in pairs(context) do
    local type = type(value)
    if type == 'string' or type == 'boolean' or type == 'number' then
      self[key] = value
    end
  end
  self._mappings = core.table.copy(context.mappings)
  self._events = core.table.copy(context.events)
  self._snapshot = Snapshot.new()
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch(dirpath)
  -- perform auto cd
  if self.auto_cd then
    vim.command('silent lcd ' .. dirpath)
  end

  self.root = Directory.new(dirpath, false, self.sort)
  self.root:open()
  self:update_status()
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
  self:cancel_all_jobs()
  self._snapshot:save(context.root, context.root.path)
  self:switch(context.root.path)
end

function Context:update_status()
  local path = vim.fn.fnamemodify(self.root.path, ':~')
  self.status = '[in] ' .. core.path.escape(path)
  vim.command('redrawstatus')
end

return Context
