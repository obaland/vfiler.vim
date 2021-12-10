local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Directory = require('vfiler/items/directory')
local Job = require('vfiler/async/job')

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
---@param configs table
function Context.new(configs)
  local self = setmetatable({}, Context)
  self:_initialize()
  self.events = core.table.copy(configs.events)
  self.mappings = core.table.copy(configs.mappings)
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
  self.status = ''
  self._async_jobs = {}
end

--- Cancel all jobs currently in progress
function Context:cancel_all_jobs()
  for _, job in ipairs(self._async_jobs) do
    job:cancel()
  end
  self._async_jobs = {}
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
  self:cancel_all_jobs()
  self.root:sort(type, true)
  self.sort = type
end

--- Create async root job
function Context:new_root_job()
  local number = #self._async_jobs + 1
  local job = Job.new {
    on_canceled = function(j)
      self._async_jobs[number] = nil
    end,

    on_completed = function(j)
      self._async_jobs[number] = nil
    end,
  }
  self._async_jobs[number] = job
  return job
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
  self.mappings = core.table.copy(context.mappings)
  self.events = core.table.copy(context.events)
  self._snapshot = Snapshot.new()
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch_async(dirpath, async_options)
  -- perform auto cd
  if self.auto_cd then
    vim.command('silent lcd ' .. dirpath)
  end
  self:update_status()

  -- TODO: expand
  self.root = Directory.new(dirpath, false, self.sort)

  local root_job = self:new_root_job()
  local job = self.root:open_async(false, async_options)
  root_job:chain(job)
  return job
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

function Context:set_waiting_status(format, ...)
  local frame = core.icon.frame(os.clock())
  local message = format:format(...)
  self.status = frame .. ' ' .. message
  vim.command('redrawstatus')
end

return Context
