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
      path = core.path.normalize(path),
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
    local link = stat.type == 'link'
    if link then
      stat = uv.fs_stat(path)
    end
    return get_stat(path, core.path.name(path), stat, link)
  end

  function M.scandir(dirpath)
    local function scandir()
      local fd = uv.fs_scandir(dirpath)
      if not fd then
        return nil
      end
      while true do
        local name, type = uv.fs_scandir_next(fd)
        if not name then
          break
        end
        local path = core.path.join(dirpath, name)
        local fstat = uv.fs_stat(path)
        if fstat then
          local stat = get_stat(path, name, fstat, type == 'link')
          coroutine.yield(stat)
        end
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
            path = path,
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
  copy_directory_format = 'robocopy /e %s %s'
else
  copy_file_format = 'cp -f %s %s'
  copy_directory_format = 'cp -fR %s %s'
end

function M.copy_directory(src, dest)
  local command = copy_directory_format:format(
    core.string.shellescape(src),
    core.string.shellescape(dest)
  )
  vim.fn.system(command)
end

function M.copy_file(src, dest)
  local command = copy_file_format:format(
    core.string.shellescape(src),
    core.string.shellescape(dest)
  )
  vim.fn.system(command)
end

function M.execute(path)
  local command
  if core.is_windows then
    command = ('start rundll32 url.dll,FileProtocolHandler %s'):format(
      vim.fn.escape(path, '#%')
    )
  elseif core.is_mac and vim.fn.executable('open') == 1 then
    -- For Mac OS
    command = ('open %s &'):format(vim.fn.shellescape(path))
  elseif core.is_cygwin then
    -- For Cygwin
    command = ('cygstart %s'):format(vim.fn.shellescape(path))
  elseif vim.fn.executable('xdg-open') == 1 then
    -- For Linux
    command = ('xdg-open %s &'):format(vim.fn.shellescape(path))
  elseif
    os.getenv('KDE_FULL_SESSION')
    and os.getenv('KDE_FULL_SESSION') == 'true'
  then
    -- For KDE
    command = ('kioclient exec %s &'):format(vim.fn.shellescape(path))
  elseif os.getenv('GNOME_DESKTOP_SESSION_ID') then
    -- For GNOME
    command = ('gnome-open %s &'):format(vim.fn.shellescape(path))
  elseif vim.fn.executable('exo-open') == 1 then
    -- For Xfce
    command = ('exo-open %s &'):format(vim.fn.shellescape(path))
  else
    core.message.error('Not supported platform.')
    return
  end
  vim.fn.system(command)
end

function M.move(src, dest)
  -- NOTE: with the Lua function, an error will occur if the file is large.
  --os.rename(M.string.shellescape(src), M.string.shellescape(dest))
  vim.fn.rename(src, dest)
end

return M
