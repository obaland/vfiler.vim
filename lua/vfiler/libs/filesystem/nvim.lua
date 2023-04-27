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
    size = stat.size,
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
    stat = uv.fs_stat(path)
  end
  return get_stat(core.path.normalize(path), core.path.name(path), stat, link)
end

function M.scandir(dirpath)
  local function scandir()
    local fd = uv.fs_scandir(dirpath)
    if not fd then
      return nil
    end
    local fcount = 0
    local done = 0
    local stats = {}
    while true do
      local name, type = uv.fs_scandir_next(fd)
      if not name then
        break
      end
      fcount = fcount + 1
      local path = core.path.join(dirpath, name)
      uv.fs_stat(path, function(_, stat)
        if stat then
          table.insert(stats, {
            path = stat.type == 'directory' and path .. '/' or path,
            name = name,
            stat = stat,
            link = type == 'link',
          })
        end
        done = done + 1
      end)
    end
    vim.fn.wait(-1, function()
      return fcount == done
    end, 1)

    -- convert stat table
    for _, s in ipairs(stats) do
      coroutine.yield(get_stat(s.path, s.name, s.stat, s.link))
    end
  end
  return coroutine.wrap(scandir)
end

return M
