local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

if core.is_nvim then
  local fs = require('vfiler/libs/filesystem/nvim')
  M.scandir = fs.scandir
  M.stat = fs.stat
else
  local fs = require('vfiler/libs/filesystem/vim')
  M.scandir = fs.scandir
  M.stat = fs.stat
end

local function escape(path)
  if core.is_windows then
    -- trim end
    path = path:gsub('[/\\]+$', '')
    -- convert path separator
    return path:gsub('/', '\\')
  else
    return vim.fn.shellescape(path)
  end
end

if core.is_windows then
  function M.copy_directory(src, dest)
    core.system(
      ('robocopy /s /e "%s" "%s"'):format(escape(src), escape(dest))
    )
    return vim.v.shell_error < 8
  end

  function M.copy_file(src, dest)
    core.system(('copy /y "%s" "%s"'):format(escape(src), escape(dest)))
    return vim.v.shell_error == 0
  end

  function M.create_file(path)
    core.system(('type nul > "%s"'):format(escape(path)))
    return core.path.filereadable(path)
  end
else
  function M.copy_directory(src, dest)
    core.system(('cp -fR %s %s'):format(escape(src), escape(dest)))
    return vim.v.shell_error == 0
  end

  function M.copy_file(src, dest)
    core.system(('cp -f %s %s'):format(escape(src), escape(dest)))
    return vim.v.shell_error == 0
  end

  function M.create_file(path)
    core.system(('touch %s'):format(escape(path)))
    return core.path.filereadable(path)
  end
end

function M.create_directory(path)
  return vim.fn.mkdir(path) == 1
end

function M.delete_directory(path)
  return vim.fn.delete(path, 'rf') == 0
end

function M.delete_file(path)
  return vim.fn.delete(path) == 0
end

function M.execute(path)
  local expr
  if core.is_windows then
    expr = ('start rundll32 url.dll,FileProtocolHandler "%s"'):format(
      escape(path)
    )
  elseif core.is_mac and vim.fn.executable('open') == 1 then
    -- For Mac OS
    expr = ('open %s &'):format(escape(path))
  elseif core.is_cygwin then
    -- For Cygwin
    expr = ('cygstart %s'):format(escape(path))
  elseif vim.fn.executable('xdg-open') == 1 then
    -- For Linux
    expr = ('xdg-open %s &'):format(escape(path))
  elseif
    os.getenv('KDE_FULL_SESSION')
    and os.getenv('KDE_FULL_SESSION') == 'true'
  then
    -- For KDE
    expr = ('kioclient exec %s &'):format(escape(path))
  elseif os.getenv('GNOME_DESKTOP_SESSION_ID') then
    -- For GNOME
    expr = ('gnome-open %s &'):format(escape(path))
  elseif vim.fn.executable('exo-open') == 1 then
    -- For Xfce
    expr = ('exo-open %s &'):format(escape(path))
  else
    core.message.error('Not supported platform.')
    return
  end
  core.system(expr)
end

--- The last modification time of the file path.
--- The result is a number,
--- this value is the number of seconds since January 1, 1970.
---@param path string
---@return number
function M.ftime(path)
  return vim.fn.getftime(path)
end

function M.move(src, dest)
  -- NOTE: with the Lua function, an error will occur if the file is large.
  --os.rename(M.string.shellescape(src), M.string.shellescape(dest))
  return vim.fn.rename(src, dest) == 0
end

return M
