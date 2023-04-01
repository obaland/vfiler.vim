local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

if core.is_nvim then
  ----------------------------------------------------------------------------
  -- for Neovim
  ----------------------------------------------------------------------------

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
    return get_stat(
      core.path.normalize(path),
      core.path.name(path),
      stat,
      link
    )
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
else
  ----------------------------------------------------------------------------
  -- for Vim
  ----------------------------------------------------------------------------

  local function get_ftype(path)
    local ftype = vim.fn.getftype(path)
    if #ftype == 0 then
      -- unknown file type
      return nil
    end

    local type
    if ftype == 'dir' then
      type = 'directory'
    elseif ftype == 'link' then
      if core.path.is_directory(path) then
        type = 'directory'
      else
        type = 'file'
      end
    else
      type = ftype
    end
    return type, (ftype == 'link')
  end

  function M.stat(path)
    local type, link = get_ftype(path)
    if not type then
      return nil
    end
    return {
      path = core.path.normalize(path),
      name = core.path.name(path),
      size = vim.fn.getfsize(path),
      time = vim.fn.getftime(path),
      mode = vim.fn.getfperm(path),
      type = type,
      link = link,
    }
  end

  function M.scandir(dirpath)
    local dicts = vim.fn.readdirex(dirpath)
    local function scandir()
      for dict in dicts() do
        local path = core.path.join(dirpath, dict.name)
        local type, link = get_ftype(path)
        if type then
          coroutine.yield({
            path = type == 'directory' and path .. '/' or path,
            name = dict.name,
            size = dict.size,
            time = dict.time,
            mode = dict.perm,
            type = type,
            link = link,
          })
        end
      end
    end
    return coroutine.wrap(scandir)
  end
end

local copy_file_format, copy_directory_format

if core.is_windows then
  copy_file_format = 'copy /y %s %s'
  copy_directory_format = 'robocopy /s /e %s %s'
else
  copy_file_format = 'cp -f %s %s'
  copy_directory_format = 'cp -fR %s %s'
end

local function escape(path)
  if core.is_windows then
    -- trim end
    path = path:gsub('[/\\]+$', '')
    -- convert path separator
    path = path:gsub('/', '\\')
    return ('"%s"'):format(vim.fn.escape(path, '/'))
  else
    return vim.fn.shellescape(path)
  end
end

function M.copy_directory(src, dest)
  local command = copy_directory_format:format(escape(src), escape(dest))
  return core.system(command)
end

function M.copy_file(src, dest)
  local command = copy_file_format:format(escape(src), escape(dest))
  return core.system(command)
end

function M.execute(path)
  if core.is_windows then
    --command = ('start rundll32 url.dll,FileProtocolHandler %s'):format(
    --  vim.fn.escape(path, '#%')
    --)
    vim.fn.execute(('!start %s'):format(vim.fn.escape(path, '#%')))
    return
  end

  local command
  local escaped_path = vim.fn.shellescape(path)
  if core.is_mac and vim.fn.executable('open') == 1 then
    -- For Mac OS
    command = ('open %s &'):format(escaped_path)
  elseif core.is_cygwin then
    -- For Cygwin
    command = ('cygstart %s'):format(escaped_path)
  elseif vim.fn.executable('xdg-open') == 1 then
    -- For Linux
    command = ('xdg-open %s &'):format(escaped_path)
  elseif
    os.getenv('KDE_FULL_SESSION')
    and os.getenv('KDE_FULL_SESSION') == 'true'
  then
    -- For KDE
    command = ('kioclient exec %s &'):format(escaped_path)
  elseif os.getenv('GNOME_DESKTOP_SESSION_ID') then
    -- For GNOME
    command = ('gnome-open %s &'):format(escaped_path)
  elseif vim.fn.executable('exo-open') == 1 then
    -- For Xfce
    command = ('exo-open %s &'):format(escaped_path)
  else
    core.message.error('Not supported platform.')
    return
  end
  M.system(command)
end

function M.move(src, dest)
  -- NOTE: with the Lua function, an error will occur if the file is large.
  --os.rename(M.string.shellescape(src), M.string.shellescape(dest))
  return vim.fn.rename(src, dest) == 0
end

return M
