local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Window = {}
Window.__index = Window

function Window.new()
  local Base = require('vfiler/views/base')
  return core.inherit(Window, Base)
end

function Window:_on_close(winid, buffer)
  local winnr = vim.fn.bufwinnr(buffer.number)
  if winnr >= 0 then
    vim.command(('silent %dhide!'):format(winnr))
  end
end

function Window:_on_open(buffer, options)
  -- open window
  core.window.open(options.layout)
  local winid = vim.fn.win_getid()
  self:_on_update(winid, buffer, options)

  -- set option
  -- NOTE: For vim, don't explicitly set the "signcolumn" option as the
  -- screen may flicker.
  --vim.set_win_option(winid, 'signcolumn', 'no')
  return winid
end

function Window:_on_update(winid, buffer, options)
  if buffer.number ~= vim.fn.winbufnr(winid) then
    vim.fn.win_gotoid(winid)
    vim.fn.win_execute(
      winid,
      ('silent noautocmd %dbuffer!'):format(buffer.number)
    )
  end

  -- resize window
  local winnr = self:winnr()
  if options.width > 0 then
    core.window.resize_width(winnr, options.width)
  end
  if options.height > 0 then
    core.window.resize_height(winnr, options.height)
  end

  -- set title to statusline
  if options.title then
    vim.set_win_option(
      winid,
      'statusline',
      ('%%#vfilerStatusLineSection# %s %%#vfilerStatusLine#'):format(
        options.title
      )
    )
  end
  return winid
end

return Window
