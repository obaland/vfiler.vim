local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')
local git = require('vfiler/libs/git')
local vim = require('vfiler/libs/vim')

local Directory = require('vfiler/items/directory')

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
    if child.opened then
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

local shared_attributes = {}
local shared_drives = {}

function Session.new(type)
  local attributes
  if type == 'buffer' then
    attributes = {}
  elseif type == 'share' then
    attributes = shared_attributes
  end

  local drives
  if type == 'share' then
    drives = shared_drives
  else
    drives = {}
  end

  return setmetatable({
    _type = type,
    _attributes = attributes,
    _drives = drives,
  }, Session)
end

function Session.expand(root, attribute)
  for _, child in ipairs(root.children) do
    local opened = attribute.opened_attributes[child.name]
    if opened then
      child:open()
      Session.expand(child, opened)
    end

    local selected = attribute.selected_names[child.name]
    if selected then
      child.selected = true
    end
  end
  return root
end

function Session:copy()
  local new = Session.new(self._type)
  if new._type ~= 'share' then
    new._drives = core.table.copy(self._drives)
  end

  if new._type == 'buffer' then
    for path, attribute in pairs(self._attributes) do
      new._attributes[path] = {
        previus_path = attribute.previus_path,
        object = ItemAttribute.copy(attribute.object),
      }
    end
  end
  return new
end

function Session:save(root, path)
  local drive = core.path.root(root.path)
  self._drives[drive] = root.path
  if self._attributes then
    self._attributes[root.path] = {
      previus_path = path,
      object = ItemAttribute.parse(root),
    }
  end
end

function Session:load(root)
  if not self._attributes then
    return nil
  end
  local attribute = self._attributes[root.path]
  if not attribute then
    return nil
  end
  Session.expand(root, attribute.object)
  return attribute.previus_path
end

function Session:get_path_in_drive(drive)
  local dirpath = self._drives[drive]
  if not dirpath then
    return nil
  end
  return dirpath
end

------------------------------------------------------------------------------
-- Context class
------------------------------------------------------------------------------

function Session.expand(root, attribute)
  for _, child in ipairs(root.children) do
    local opened = attribute.opened_attributes[child.name]
    if opened then
      child:open()
      Session.expand(child, opened)
    end

    local selected = attribute.selected_names[child.name]
    if selected then
      child.selected = true
    end
  end
  return root
end

local function walk_directories(root)
  local function walk(item)
    if item.children then
      for _, child in ipairs(item.children) do
        if child.type == 'directory' then
          walk(child)
          coroutine.yield(child)
        end
      end
    end
  end
  return coroutine.wrap(function()
    walk(root)
  end)
end

local Context = {}
Context.__index = Context

--- Create a context object
---@param configs table
function Context.new(configs)
  local self = setmetatable({}, Context)
  self:_initialize()
  self.options = core.table.copy(configs.options)
  self.events = core.table.copy(configs.events)
  self.mappings = core.table.copy(configs.mappings)
  self._session = Session.new(self.options.session)
  self._git_enabled = self:_check_git_enabled()
  return self
end

--- Copy to context
function Context:copy()
  local configs = {
    options = self.options,
    events = self.events,
    mappings = self.mappings,
  }
  local new = Context.new(configs)
  new._session = self._session:copy()
  return new
end

--- Find the specified path from the current root
---@param path string
function Context:find(path, recursive)
  path = core.path.normalize(path)
  local s, e = path:find(self.root.path)
  if not s then
    return nil
  end
  -- extract except for path separator
  local names = vim.fn.split(path:sub(e + 1), '/')
  if #names == 0 or (recursive and #names > 1) then
    return nil
  end
  local target = self.root
  for i, name in ipairs(names) do
    for _, child in pairs(target.children) do
      if name == child.name then
        if child.type == 'directory' then
          if i == #names then
            return child
          else
            if not child.opened then
              child:open()
            end
            target = child
            break
          end
        else
          return child
        end
      end
    end
  end
  return nil
end

--- Save the path in the current context
---@param path string
function Context:save(path)
  if not self.root then
    return
  end
  self._session:save(self.root, path)
end

--- Get the parent directory path of the current context
function Context:parent_path()
  if self.root.parent then
    return self.root.parent.path
  end
  return core.path.parent(self.root.path)
end

-- Reload the current directory path
function Context:reload()
  local root_path = self.root.path
  if vim.fn.getftime(root_path) > self.root.time then
    self:switch(root_path)
    return
  end
  local job = self:_reload_gitstatus_job(root_path)
  for dir in walk_directories(self) do
    if dir.opened then
      if vim.fn.getftime(dir.path) > dir.time then
        dir:open()
      end
    end
  end

  if job then
    job:wait()
  end
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch(dirpath)
  dirpath = core.path.normalize(dirpath)
  -- perform auto cd
  if self.options.auto_cd then
    vim.fn.execute('lcd ' .. dirpath, 'silent')
  end

  -- reload git status
  local job = self:_reload_gitstatus_job(dirpath)
  self.root = Directory.new(fs.stat(dirpath))
  self.root:open()

  local path = self._session:load(self.root)
  if job then
    job:wait()
  end
  return path
end

--- Switch the context to the specified drive path
---@param drive string
function Context:switch_drive(drive)
  local dirpath = self._session:get_path_in_drive(drive)
  if not dirpath then
    dirpath = drive
  end
  return self:switch(dirpath)
end

--- Update from another context
---@param context table
function Context:update(context)
  self.options = core.table.copy(context.options)
  self.mappings = core.table.copy(context.mappings)
  self.events = core.table.copy(context.events)
  self._git_enabled = self:_check_git_enabled()
end

function Context:_check_git_enabled()
  if not self.options.git.enabled or vim.fn.executable('git') ~= 1 then
    return false
  end
  return self.options.columns:match('git%w*') ~= nil
end

function Context:_initialize()
  self.clipboard = nil
  self.extension = nil
  self.linked = nil
  self.root = nil
  self.gitroot = nil
  self.gitstatus = {}
  self.in_preview = {
    preview = nil,
    once = false,
  }
end

function Context:_reload_gitstatus_job(dirpath)
  if not self._git_enabled then
    return nil
  end
  if not (self.gitroot and dirpath:match(self.gitroot)) then
    self.gitroot = git.get_toplevel(dirpath)
  end
  if not self.gitroot then
    return nil
  end
  return git.reload_status(self.gitroot, {
    untracked = self.options.git.untracked,
    ignored = self.options.git.ignored,
  }, function(status)
    self.gitstatus = status
  end)
end

return Context
