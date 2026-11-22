local core = require('vfiler/libs/core')
local git = require('vfiler/libs/git')
local vim = require('vfiler/libs/vim')

local Git = {}
Git.__index = Git

local uv = core.is_nvim and not core.is_windows and vim.nvim.loop

local function resolve_path(path)
  if
    uv
    and type(path) == 'string'
    and path:sub(1, 1) == '/'
    and not path:find('\\', 1, true)
    and uv.fs_realpath(path) == path
  then
    local stat = uv.fs_stat(path)
    if stat and stat.type == 'file' then
      return path
    end
  end
  return core.path.normalize(vim.fn.resolve(path))
end

--- Create a git object
---@param options table
function Git.new(options)
  local self = setmetatable({
    _root_lookups = {},
    _requests = {},
    _request_id = 0,
    _statuses = {},
    _status_cache = {},
  }, Git)
  self:reset(options)
  return self
end

--- Asynchronously retrieve the status of all files in the repository
--- containing the specified directory.
---@param dirpath string
---@param callback function
function Git:status_async(dirpath, callback)
  if not (self._git_executable and self._options.enabled) then
    return
  end

  self._request_id = self._request_id + 1
  local id = self._request_id
  local lookup = self._root_lookups[dirpath]
  if lookup then
    lookup.id = id
    lookup.callback = callback
    return
  end

  lookup = { id = id, callback = callback }
  self._root_lookups[dirpath] = lookup

  local job = git.root_async(dirpath, function(root)
    self._root_lookups[dirpath] = nil
    if not (root and self._options.enabled) then
      return
    end

    local request = self._requests[root]
    if request and lookup.id < request.id then
      return
    end

    if not request then
      request = {}
      self._requests[root] = request
    end

    request.id = lookup.id
    request.callback = lookup.callback
    if not request.running then
      self:_start_status(root, request)
    end
  end)
  if not job and self._root_lookups[dirpath] == lookup then
    self._root_lookups[dirpath] = nil
  end
end

--- Reset from another options
---@param options table
function Git:reset(options)
  self._options = core.table.copy(options)
  self._git_executable = vim.fn.executable('git') == 1
end

--- Check whether any repository has Git changes to display.
function Git:has_status()
  if self._options.enabled then
    for _, status in pairs(self._statuses) do
      if next(status) then
        return true
      end
    end
  end
  return false
end

--- Get the git status of the file
---@param path string
---@return table?
function Git:status(path)
  if not self._options.enabled or not next(self._statuses) then
    return nil
  end

  local resolved = resolve_path(path)
  local cached = self._status_cache[resolved]
  if cached then
    return cached
  end
  for root, status in pairs(self._statuses) do
    if root == resolved:sub(1, #root) then
      self._status_cache = status
      return status[resolved]
    end
  end
  return nil
end

--- Iterator to walk each status
---@return function?
function Git:walk_status()
  if not self._statuses then
    return nil
  end
  local function _walk()
    for path, status in pairs(self._statuses) do
      coroutine.yield(path, status)
    end
  end
  return coroutine.wrap(_walk)
end

function Git:_start_status(root, request)
  local callback = request.callback
  request.callback = nil
  request.running = true

  local job = git.status_async(root, self._options, function(status)
    request.running = false
    if not self._options.enabled then
      request.callback = nil
      return
    end

    if request.callback then
      self:_start_status(root, request)
      return
    end

    self._status_cache = {}
    self._statuses[root] = status
    callback(self, root, status)
  end)
  if not job then
    request.running = false
  end
end


return Git
