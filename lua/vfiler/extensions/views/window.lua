local core = require('vfiler/core')
local mapping = require('vfiler/mapping')
local vim = require('vfiler/vim')

local Window = {}
Window.__index = Window

function Window.new()
  return setmetatable({
    source_winid = vim.fn.win_getid(),
    winid = 0,
    bufnr = 0,
  }, Window)
end

function Window:close()
  local winnr = vim.fn.bufwinnr(self.bufnr)
  if winnr >= 0 then
    vim.command(('silent %dquit!'):format(winnr))
  end
end

function Window:define_mapping(mappings, funcstr)
  return mapping.define(self.bufnr, mappings, funcstr)
end

function Window:draw(lines)
  vim.command('silent %delete _')
  vim.fn.setbufline(self.bufnr, 1, vim.to_vimlist(lines))
end

function Window:open(lines, options)
  self.winid = self:_on_open(lines, options)
  self.bufnr = vim.fn.winbufnr(self.winid)

  -- set buffer options
  -- default buffer options
  local bufoptions = {
    bufhidden = 'delete',
    buflisted = false,
    buftype = 'nofile',
    swapfile = false,
  }
  vim.set_buf_options(
    self.bufnr,
    core.table.merge(bufoptions, options.bufoptions)
  )

  -- set window options
  -- default window options
  local winoptions = {
    colorcolumn = '',
    conceallevel = 2,
    concealcursor = 'nvc',
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = true,
    spell = false,
    wrap = false,
  }
  vim.set_win_options(
    self.winid,
    core.table.merge(winoptions, options.winoptions)
  )
  return self.winid
end

function Window:winnr()
  return vim.fn.bufwinnr(self.bufnr)
end

function Window:_on_open(lines, options)
  -- open window
  core.window.open(options.layout)
  vim.command('silent edit ' .. 'vfiler/' .. options.name)
  local winid = vim.fn.win_getid()

  -- resize window
  if options.width > 0 then
    core.window.resize_width(options.width)
  end
  if options.height > 0 then
    core.window.resize_height(options.height)
  end

  -- set name to statusline
  if options.name then
    vim.set_win_option(winid, 'statusline', options.name)
  end
  return winid
end

return Window
