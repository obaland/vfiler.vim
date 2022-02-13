local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Window = {}
Window.__index = Window

function Window.new()
  return setmetatable({
    _bufnr = 0,
  }, Window)
end

function Window:close()
  local winnr = vim.fn.bufwinnr(self._bufnr)
  if winnr <= 0 then
    return
  end
  vim.fn.execute(('%dclose!'):format(winnr))
end

function Window:id()
  if self._bufnr <= 0 then
    return 0
  end
  return vim.fn.bufwinid(self._bufnr)
end

function Window:open(buffer, config)
  self._bufnr = buffer.number
  local winid = self:id()
  if winid > 0 then
    self:_on_update(winid, buffer, config)
  else
    self:_on_open(buffer, config)
  end

  -- default window options
  self:set_options({
    colorcolumn = '',
    conceallevel = 2,
    concealcursor = 'nvc',
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = true,
    relativenumber = false,
    spell = false,
    wrap = false,
  })
  return self:id()
end

function Window:set_option(name, value)
  vim.set_win_option(self:id(), name, value)
end

function Window:set_options(options)
  vim.set_win_options(self:id(), options)
end

function Window:resize(width, height)
  local winnr = vim.fn.win_id2win(self:id())
  local fixwidth = false
  if width > 0 then
    core.window.resize_width(winnr, width)
    fixwidth = true
  end
  self:set_option('winfixwidth', fixwidth)
  local fixheight = false
  if height > 0 then
    core.window.resize_height(winnr, height)
    fixheight = true
  end
  self:set_option('winfixheight', fixheight)
end

function Window:set_title(title)
  -- set title to statusline
  local format = '%%#vfilerStatusLineSection# %s %%#vfilerStatusLine#'
  local statusline = format:format(title)
  vim.set_win_option(self:id(), 'statusline', statusline)
end

function Window:type()
  return 'window'
end

function Window:_on_open(buffer, config)
  local winid = vim.fn.win_getid()
  self:_on_update(winid, buffer, config)
end

function Window:_on_update(winid, buffer, config)
  if buffer.number == vim.fn.winbufnr(winid) then
    return
  end
  vim.fn.win_gotoid(winid)
  vim.fn.win_execute(winid, ('%dbuffer!'):format(buffer.number))
  self:resize(config.width, config.height)
end

return Window
