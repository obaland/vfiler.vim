local core = require('vfiler/libs/core')
local fs = require('vfiler/libs/filesystem')
local vim = require('vfiler/libs/vim')

local Directory = require('vfiler/items/directory')
local Session = require('vfiler/context/session')

local Context = {}
Context.__index = Context

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

--- Create a context object
---@param configs table
function Context.new(configs)
  local self = setmetatable({}, Context)
  self:_initialize()
  self.options = core.table.copy(configs.options)
  self.events = core.table.copy(configs.events)
  self.mappings = core.table.copy(configs.mappings)
  self._session = Session.new(self.options.session)
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

--- Open the tree recursively according to the specified path
---@param path string
function Context:open_tree(path)
  path = core.path.normalize(path)
  local s, e = path:find(self.root.path, 1, true)
  if not s then
    return nil
  end
  -- extract except for path separator
  local names = vim.fn.split(path:sub(e + 1), '/')
  if #names == 0 then
    return nil
  end
  local directory = self.root
  for i, name in ipairs(names) do
    for _, child in pairs(directory.children) do
      if name == child.name then
        if child.type == 'directory' then
          if i == #names then
            return child
          else
            if not child.opened then
              child:open()
            end
            directory = child
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

-- Rerform auto cd
function Context:perform_auto_cd()
  if self.options.auto_cd then
    vim.fn.execute('lcd ' .. vim.fn.fnameescape(self.root.path), 'silent')
  end
end

-- Reload the current directory path
---@param reload_all_dir boolean
function Context:reload(reload_all_dir)
  local root_path = self.root.path
  if reload_all_dir or vim.fn.getftime(root_path) > self.root.time then
    self:switch(root_path)
    return
  end
  for dir in walk_directories(self.root) do
    if dir.opened then
      if vim.fn.getftime(dir.path) > dir.time then
        dir:update()
        dir:open()
      end
    end
  end
end

--- Switch the context to the specified directory path
---@param dirpath string
function Context:switch(dirpath)
  dirpath = core.path.normalize(dirpath)
  self.root = Directory.new(fs.stat(dirpath))
  self.root:open()

  local path = self._session:load(self.root)
  self:perform_auto_cd()
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
end

--- Get directory history
function Context:directory_history()
  return self._session:directory_history()
end

function Context:_initialize()
  self.extension = nil
  self.linked = nil
  self.root = nil
  self.in_preview = {
    preview = nil,
    once = false,
  }
end

return Context
