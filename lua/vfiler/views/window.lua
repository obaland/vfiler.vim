local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Window = {}
Window.__index = Window

function Window.new(name)
  local Base = require('vfiler/views/base')
  return core.inherit(Window, Base, name)
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
  return winid
end

function Window:_on_update(winid, buffer, options)
  if buffer.number ~= vim.fn.winbufnr(winid) then
    vim.fn.win_gotoid(winid)
    vim.fn.win_execute(winid, 'silent noautocmd buffer! ' .. buffer.number)
  end

  -- resize window
  if options.width > 0 then
    core.window.resize_width(options.width)
  end
  if options.height > 0 then
    core.window.resize_height(options.height)
  end

  -- set name to statusline
  if self.name then
    vim.set_win_option(
      winid,
      'statusline',
      ('%%#vfilerStatusLineSection# %s %%#vfilerStatusLine#'):format(
        self.name
      )
    )
  end
  return winid
end

return Window
