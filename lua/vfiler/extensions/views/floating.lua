local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Floating = {}

function Floating.new(options)
  local Window = require('vfiler/extensions/views/window')
  return core.inherit(Floating, Window, options)
end

function Floating:close()
  if self.winid > 0 then
    vim.api.nvim_win_close(self.winid, true)
    self.winid = 0
  end
  if self._title then
    vim.api.nvim_win_close(self._title.winid, true)
    self._title = nil
  end
end

function Floating:draw(name, texts)
  local winnr = self:winnr()
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, texts)

  -- set window options
  vim.set_win_options(winnr, self.winoptions)
end

function Floating:_on_win_option(name, texts)
  -- calculate min width and height
  local options = {
    minwidth = 1,
    minheight = 1,
  }

  local floating = core.table.copy(self.options.floating)
  local wwidth = vim.fn.winwidth(self.source_winid)
  local wheight = vim.fn.winheight(self.source_winid)

  if name and #name > 0 then
    -- '2' is space width
    floating.minwidth = math.max(#name + 2, floating.minwidth)
  end

  -- position
  options.relative = floating.relative and 'win' or 'editor'

  -- decide width and height
  if floating.minwidth then
    options.minwidth = self:_winvalue(wwidth, floating.minwidth)
  end
  if floating.minheight then
    options.minheight = self:_winvalue(wheight, floating.minheight)
  end

  -- adjust width: match to the top
  options.width = self:_winwidth(
    wwidth, floating.width or 'auto', options.minwidth, wwidth, texts
  )
  options.height = self:_winheight(
    wheight, floating.height or 'auto', options.minheight, wheight, texts
  )

  -- claculate position
  options.row = math.floor((wheight - options.height) / 2)
  options.col = math.floor((wwidth - options.width) / 2)
  return options
end

function Floating:_on_open(name, texts, options)
  local win_options = {
    border = 'rounded',
    col = options.col,
    focusable = true,
    height = options.height,
    noautocmd = false,
    relative = options.relative,
    row = options.row,
    width = options.width,
    zindex = 200,
  }
  if win_options.relative == 'win' then
    win_options.win = self.source_winid
  end

  local listed = self.bufoptions.buflisted and true or false
  local buffer = vim.api.nvim_create_buf(listed, true)
  local winid = vim.api.nvim_open_win(buffer, true, win_options)

  -- set options
  vim.api.nvim_win_set_option(winid, 'winhighlight', 'Normal:Normal')
  vim.api.nvim_win_set_option(winid, 'number', false)

  -- open title window
  if name and #name > 0 then
    self:_open_tile(name, win_options)
  end
  return winid
end

function Floating:_open_tile(name, content_option)
  local title = ' ' .. name .. ' '
  local option = {
    col = content_option.col + 1,
    focusable = false,
    height = 1,
    noautocmd = false,
    relative = content_option.relative,
    row = content_option.row,
    width = #title,
    zindex = content_option.zindex + 1,
  }
  if option.relative == 'win' then
    option.win = self.source_winid
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, false, option)

  -- set options
  vim.api.nvim_win_set_option(winid, 'winhighlight', 'Normal:Constant')
  vim.api.nvim_win_set_option(winid, 'cursorline', false)

  -- set title name
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, {title})

  self._title = {
    bufnr = bufnr,
    winid = winid,
  }
end

return Floating
