local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Job = require('vfiler/libs/async/job')

local M = {}

local function create_status_commands(rootpath, path, options)
  local commands = {
    'git',
    '-C',
    rootpath,
    '--no-optional-locks',
    'status',
    '--porcelain=v1',
  }

  -- Options
  if options.untracked then
    table.insert(commands, '-u')
  end
  if options.ignored then
    table.insert(commands, '--ignored=matching')
  else
    table.insert(commands, '--ignored=no')
  end

  -- path
  if path then
    table.insert(commands, path)
  end
  return commands
end

local function parse_git_status(rootpath, result)
  local status = result:sub(1, 2)
  local rpath = result:sub(4, -1)
  -- for renamed
  local splitted = vim.list.from(vim.fn.split(rpath, ' -> '))
  rpath = splitted[#splitted]
  -- Removing: extra characters
  rpath = rpath:gsub('^"', ''):gsub('^"', '')
  return core.path.join(rootpath, rpath),
    { us = status:sub(1, 1), them = status:sub(2, 2) }
end

local function update_directory_statuses(rootpath, statuses)
  local function update(dirstatus, status)
    if status.us == '!' then
      return
    end
    if status.us ~= ' ' and status.us ~= '?' then
      dirstatus.us = '*'
    end
    if status.them ~= ' ' then
      dirstatus.them = '*'
    end
  end

  local dirs = {}
  for path, status in pairs(statuses) do
    local modified = core.path.parent(path)
    local dirstatus = dirs[modified]
    if not dirstatus then
      dirstatus = {
        us = ' ',
        them = ' ',
      }
      dirs[modified] = dirstatus
    end
    update(dirstatus, status)
  end

  for path, status in pairs(dirs) do
    while rootpath ~= path do
      local dirstatus = statuses[path]
      if dirstatus then
        update(dirstatus, status)
      else
        statuses[path] = {
          us = status.us,
          them = status.them,
        }
      end
      path = core.path.parent(path)
    end
  end
  return statuses
end

local function update_dirstatus(dirstatus, status)
  if status.us == '!' then
    return
  end
  if status.us ~= ' ' and status.us ~= '?' then
    dirstatus.us = '*'
  end
  if status.them ~= ' ' then
    dirstatus.them = '*'
  end
end

function M.get_toplevel(dirpath)
  local command = ('git -C "%s" rev-parse --show-toplevel'):format(dirpath)
  local path = core.system(command)
  if (not path or #path == 0) or path:match('^fatal') then
    return nil
  end
  return core.path.normalize(path:sub(0, -2))
end

function M.reload_status_async(rootpath, options, on_completed)
  local commands = create_status_commands(rootpath, nil, options)
  local gitstatus = {}
  local job = Job.new()
  job:start(commands, {
    on_received = function(self, result)
      local path, status = parse_git_status(rootpath, result)
      gitstatus[path] = status
    end,

    on_completed = function(self, code)
      update_directory_statuses(rootpath, gitstatus)
      on_completed(gitstatus)
    end,
  })
  return job
end

function M.reload_status_file(rootpath, path, options)
  local commands = create_status_commands(
    '"' .. rootpath .. '"',
    '"' .. path .. '"',
    options
  )
  local result = core.system(table.concat(commands, ' '))
  if #result == 0 then
    return nil
  end

  local gitstatus = {}
  local _, status = parse_git_status(rootpath, result)
  gitstatus[path] = status
  update_directory_statuses(rootpath, gitstatus)
  return gitstatus
end

return M
