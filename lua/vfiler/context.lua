local core = require('vfiler/core')
local git = require('vfiler/git')
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
-- Session class
------------------------------------------------------------------------------

local Session = {}
Session.__index = Session

function Session.new()
  return setmetatable({
    _drives = {},
    _attributes = {},
  }, Session)
end

function Session:copy(session)
  self._drives = core.table.copy(session._drives)
  for path, attribute in pairs(self._attributes) do
    self._attributes[path] = {
      previus_path = attribute.previus_path,
      object = ItemAttribute.copy(attribute.object),
    }
  end
end

function Session:get_previous_path(rootpath)
  local attribute = self._attributes[rootpath]
  if not attribute then
    return nil
  end
  return attribute.previus_path
end

function Session:save(root, path)
  local drive = core.path.root(root.path)
  self._drives[drive] = root.path
  self._attributes[root.path] = {
    previus_path = path,
    object = ItemAttribute.parse(root),
  }
end

function Session:load(root)
  local attribute = self._attributes[root.path]
  if not attribute then
    return nil
  end
  expand(root, attribute.object)
  return attribute.previus_path
end

function Session:load_dirpath(drive)
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
  self.events = core.table.copy(configs.events)
  self.mappings = core.table.copy(configs.mappings)
  self.gitroot = nil
  self.gitstatus = {}
  self._session = Session.new()

  -- set options
  local ignores = {
    new = true,
  }
  for key, value in pairs(configs.options) do
    -- skip ignore option
    local ignore = ignores[key]
    if not ignore then
      if self[key] then
        core.message.warning('Duplicate "%s" option.', key)
      end
      self[key] = value
    end
  end
  self._git_enabled = self:_check_git_enabled()
  return self
end

--- Save the path in the current context
---@param path string
function Context:save(path)
  if not self.root then
    return
  end
  self._session:save(self.root, path)
end

--- Duplicate context
function Context:duplicate()
  local new = setmetatable({}, Context)
  new:_initialize()
  new:reset(self)
  new._session:copy(self._session)
  return new
end

--- Get the parent directory path of the current context
function Context:parent_path()
  if self.root.parent then
    return self.root.parent.path
  end
  return core.path.parent(self.root.path)
end

--- Reload Git status
---@param on_completed function
function Context:reload_gitstatus(on_completed)
  if not self.gitroot then
    return
  end

  self:_reload_gitstatus(function(gitstatus)
    self.gitstatus = gitstatus
    on_completed(self)
  end)
end

--- Reset from another context
---@param context table
function Context:reset(context)
  self:_initialize()
  self:update(context)
  self._session = Session.new()
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch(dirpath, on_completed)
  dirpath = core.path.normalize(dirpath)
  -- perform auto cd
  if self.auto_cd then
    vim.command('silent lcd ' .. dirpath)
  end

  local previus_path = self._session:get_previous_path(dirpath)
  local num_processes = 1
  local completed = 0

  -- reload git status
  if self._git_enabled then
    if not (self.gitroot and dirpath:match(self.gitroot)) then
      self.gitroot = git.get_toplevel(dirpath)
    end
    if self.gitroot then
      num_processes = num_processes + 1
      self:_reload_gitstatus(function(gitstatus)
        self.gitstatus = gitstatus
        completed = completed + 1
        if completed >= num_processes then
          on_completed(self, previus_path)
        end
      end)
    end
  end

  self.root = Directory.new(dirpath, false)
  self.root:open()
  self._session:load(self.root)

  completed = completed + 1
  if completed >= num_processes then
    on_completed(self, previus_path)
  end
end

--- Switch the context to the specified drive path
---@param drive string
function Context:switch_drive(drive, on_completed)
  local dirpath = self._session:load_dirpath(drive)
  if not dirpath then
    dirpath = drive
  end
  self:switch(dirpath, on_completed)
end

--- Synchronize with other context
---@param context table
function Context:sync(context, on_completed)
  self._session:save(context.root, context.root.path)
  self:switch(context.root.path, on_completed)
end

--- Update from another context
---@param context table
function Context:update(context)
  -- copy options
  for key, value in pairs(context) do
    local type = type(value)
    if type == 'string' or type == 'boolean' or type == 'number' then
      self[key] = value
    end
  end
  self.mappings = core.table.copy(context.mappings)
  self.events = core.table.copy(context.events)
end

function Context:_check_git_enabled()
  if not self.git or vim.fn.executable('git') ~= 1 then
    return false
  end
  return self.columns:match('git%w*') ~= nil
end

function Context:_initialize()
  self.clipboard = nil
  self.extension = nil
  self.linked = nil
  self.root = nil
end

function Context:_reload_gitstatus(on_completed)
  local options = {
    untracked = self.git_untracked,
    ignored = self.git_ignored,
  }
  git.reload_status(self.gitroot, options, on_completed)
end

return Context
