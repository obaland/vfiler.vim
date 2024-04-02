local core = require('vfiler/libs/core')
local git = require('vfiler/libs/git')
local vim = require('vfiler/libs/vim')

local Git = {}
Git.__index = Git

--- Create a git object
---@param options table
function Git.new(options)
  local self = setmetatable({
    _jobs = {},
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

  git.root_async(dirpath, function(root)
    if not root then
      return
    end

    -- Stop previous job
    local job = self._jobs[root]
    if job then
      job:stop()
    end

    self._status_cache = {}
    self._jobs[root] = git.status_async(root, self._options, function(status)
      vim.nvim.print(status)
      self._statuses[root] = status
      callback(self, root, status)
      self._jobs[root] = nil
    end)
  end)
end

--- Reset from another options
---@param options table
function Git:reset(options)
  self._options = core.table.copy(options)
  self._git_executable = vim.fn.executable('git') == 1
end

--- Get the git status of the file
---@param path string
---@return table?
function Git:status(path)
  local resolved = core.path.normalize(vim.fn.resolve(path))
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

return Git
