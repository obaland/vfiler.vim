local fs = require('vfiler/libs/filesystem')
local git = require('vfiler/libs/git')
local vim = require('vfiler/libs/vim')

local Git = {}
Git.__index = Git

--- Create a git object
---@param options table
function Git.new(options)
  return setmetatable({
    _options = options,
    _jobs = {},
    _status_reports = {},
    _status_cache = {},
    _git_executable = vim.fn.executable('git') == 1,
  }, Git)
end

--- Update git status
---@param dirpath string
---@param callback function
function Git:reload_async(dirpath, callback)
  if not (self._git_executable and self._options.enabled) then
    return
  end

  git.get_toplevel_async(dirpath, function(toplevel)
    if not toplevel then
      return
    end

    -- Update when the git status acquisition date/time is newer than
    -- the modification date/time of the target directory.
    local report = self._status_reports[toplevel]
    if report and report.time > fs.ftime(dirpath) then
      return
    end

    -- Stop previous job
    local job = self._jobs[toplevel]
    if job then
      job:stop()
    end

    self._jobs[toplevel] = git.reload_status_async(
      toplevel,
      self._options,
      function(status)
        self._status_reports[toplevel] = {
          time = vim.fn.localtime(),
          status = status,
        }
        callback(self, toplevel, status)
        self._jobs[toplevel] = nil
      end
    )
  end)
end

--- Get the git status of the file
---@param path string
---@return table?
function Git:get_status(path)
  local status = self._status_cache[path]
  if status then
    return status
  end
  for toplevel, report in pairs(self._status_reports) do
    if toplevel == path:sub(1, #toplevel) then
      self._status_cache = report.status
      return report.status[path]
    end
  end
  return nil
end

--- Iterator to walk each status
---@return function?
function Git:walk_status()
  if not self._status_reports then
    return nil
  end
  local function _walk()
    for _, report in pairs(self._status_reports) do
      for path, status in pairs(report.status) do
        coroutine.yield(path, status)
      end
    end
  end
  return coroutine.wrap(_walk)
end

return Git
