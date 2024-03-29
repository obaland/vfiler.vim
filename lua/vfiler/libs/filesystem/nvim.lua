local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')
local uv = vim.nvim.loop

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

local function to_mode_string(mode)
  -- mask the file type field
  mode = mode % 512
  local s = ''
  while mode > 0 do
    s = perm_patterns[(mode % 8) + 1] .. s
    mode = math.modf(mode / 8)
  end
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
  local fcount = 0
  local done = 0
  while true do
    local name, type = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    fcount = fcount + 1
    local path = core.path.join(dirpath, name)
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
        done = done + 1
      elseif type == 'link' then
        uv.fs_lstat(path, function(_, lstat)
          if lstat and callback then
            callback(get_stat(path, name, lstat, true))
          end
          done = done + 1
        end)
      else
        done = done + 1
      end
    end)
  end
  vim.fn.wait(-1, function()
    return fcount == done
  end, 1)
end

return M
