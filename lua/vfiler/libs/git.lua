local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Job = require('vfiler/libs/async/job')

local M = {}

local path_escapes = {
  a = '\a',
  b = '\b',
  t = '\t',
  n = '\n',
  v = '\v',
  f = '\f',
  r = '\r',
  ['"'] = '"',
  ['\\'] = '\\',
}

-- Decode Git's C-style quoted paths, including octal UTF-8 bytes.
local function unquote_path(path)
  if path:sub(1, 1) ~= '"' then
    return path
  end
  local decoded = {}
  local i = 2
  while i < #path do
    local pos = path:find('\\', i, true)
    if not pos or pos == #path then
      table.insert(decoded, path:sub(i, -2))
      break
    end
    if pos > i then
      table.insert(decoded, path:sub(i, pos - 1))
    end

    local escape = path:sub(pos + 1, pos + 1)
    local char
    if escape:match('[0-7]') then
      char = string.char(tonumber(path:sub(pos + 1, pos + 3), 8))
      i = pos + 4
    else
      char = path_escapes[escape]
      i = pos + 2
    end
    table.insert(decoded, char)
  end
  return table.concat(decoded)
end

-- The rename separator is meaningful only outside quoted filenames.
local function renamed_path(paths)
  local quoted, escaped = false, false
  for i = 1, #paths do
    local char = paths:sub(i, i)
    if escaped then
      escaped = false
    elseif quoted and char == '\\' then
      escaped = true
    elseif char == '"' then
      quoted = not quoted
    elseif not quoted and paths:sub(i, i + 3) == ' -> ' then
      return paths:sub(i + 4)
    end
  end
  return paths
end

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

local function create_toplevel_commands(dirpath)
  return {
    'git',
    '-C',
    dirpath,
    'rev-parse',
    '--show-toplevel',
  }
end

local function parse_git_status(result)
  result = result:gsub('[\r\n]+$', '')
  local status = result:sub(1, 2)
  local rpath = result:sub(4)
  if status:find('[RC]') then
    rpath = renamed_path(rpath)
  end

  return unquote_path(rpath), { us = status:sub(1, 1), them = status:sub(2, 2) }
end

local function parse_toplevel_path(result)
  if (not result or #result == 0) or result:match('fatal:%s') then
    return nil
  end
  return core.path.normalize(result:sub(0, -1))
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

  local parents = {}
  for path, status in pairs(dirs) do
    local cur = path
    while rootpath ~= cur do
      local dirstatus = statuses[cur]
      if dirstatus then
        update(dirstatus, status)
      else
        statuses[cur] = {
          us = status.us,
          them = status.them,
        }
      end
      local parent = parents[cur]
      if not parent then
        parent = core.path.parent(cur)
        parents[cur] = parent
      end
      cur = parent
    end
  end
  return statuses
end

--- Obtains the root directory path of the repository containing
--- the specified directory.
---@param dirpath string
---@return string?
function M.root(dirpath)
  local commands = create_toplevel_commands('"' .. dirpath .. '"')
  local result = core.system(table.concat(commands, ' '))
  return parse_toplevel_path(vim.fn.trim(result, ''))
end

--- Asynchronously obtains the root directory path of the repository
--- containing the specified directory.
---@param dirpath string
---@param callback function
---@return table?
function M.root_async(dirpath, callback)
  local commands = create_toplevel_commands(dirpath)
  local rootpath
  local job = Job.new()
  local started = job:start(commands, {
    on_received = function(_, result)
      rootpath = parse_toplevel_path(result)
    end,

    on_completed = function(_, code)
      callback(rootpath)
    end,
  })
  return started and job or nil
end

--- Get the status of all files in the repository asynchronously.
---@param rootpath string
---@param options table
---@param callback function
---@return table?
function M.status_async(rootpath, options, callback)
  local commands = create_status_commands(rootpath, nil, options)
  local prefix = rootpath:sub(-1) == '/' and rootpath or rootpath .. '/'
  local gitstatus = {}
  local job = Job.new()
  local started = job:start(commands, {
    on_received = function(_, result)
      local path, status = parse_git_status(result)
      gitstatus[prefix .. path] = status
    end,

    on_completed = function(_, code)
      update_directory_statuses(rootpath, gitstatus)
      callback(gitstatus)
    end,
  })
  return started and job or nil
end

--- Get the status of a file in the repository.
---@param rootpath string
---@param path string
---@param options table
---@return table?
function M.status_file(rootpath, path, options)
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
  local _, status = parse_git_status(result)
  gitstatus[path] = status
  update_directory_statuses(rootpath, gitstatus)
  return gitstatus
end

return M
