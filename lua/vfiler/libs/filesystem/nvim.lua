local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')
local uv = vim.nvim.loop

local MAX_PENDING_STATS = 512

local perm_patterns = {
  '---',
  '--x',
  '-w-',
  '-wx',
  'r--',
  'r-x',
  'rw-',
  'rwx',
}

local M = {}
local mode_cache = {}

local function to_mode_string(mode)
  local permissions = mode % 512
  local cached = mode_cache[permissions]
  if cached then
    return cached
  end

  mode = permissions
  local s = ''
  for _ = 1, 3 do
    s = perm_patterns[(mode % 8) + 1] .. s
    mode = math.modf(mode / 8)
  end
  mode_cache[permissions] = s
  return s
end

local function get_stat(path, name, stat, link)
  return {
    path = path,
    name = name,
    size = (stat.type == 'directory') and 0 or stat.size,
    time = stat.mtime.sec,
    mode = to_mode_string(stat.mode),
    type = stat.type,
    link = link,
  }
end

function M.stat(path)
  local stat = uv.fs_lstat(path)
  if not stat then
    return nil
  end
  local link = stat.type == 'link'
  if link then
    local real_stat = uv.fs_stat(path)
    if real_stat then
      stat = real_stat
    end
  end
  return get_stat(core.path.normalize(path), core.path.name(path), stat, link)
end

function M.scandir(dirpath, callback)
  local fd = uv.fs_scandir(dirpath)
  if not fd then
    return nil
  end

  local prefix = core.path.join(dirpath, '')
  local pending = 0
  local function stats_done()
    return pending == 0
  end

  while true do
    local name, type = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    pending = pending + 1
    local path = prefix .. name
    if name:find('\\', 1, true) then
      path = core.path.join(dirpath, name)
    end
    uv.fs_stat(path, function(_, stat)
      if stat and callback then
        callback(
          get_stat(
            (stat.type == 'directory') and path .. '/' or path,
            name,
            stat,
            type == 'link'
          )
        )
        pending = pending - 1
      elseif type == 'link' then
        uv.fs_lstat(path, function(_, lstat)
          if lstat and callback then
            callback(get_stat(path, name, lstat, true))
          end
          pending = pending - 1
        end)
      else
        pending = pending - 1
      end
    end)

    if pending == MAX_PENDING_STATS then
      if vim.fn.wait(-1, stats_done, 1) ~= 0 then
        return
      end
    end
  end

  if pending > 0 then
    vim.fn.wait(-1, stats_done, 1)
  end
end

return M
