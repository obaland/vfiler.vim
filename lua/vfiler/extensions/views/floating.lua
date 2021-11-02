local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Floating = {}

function Floating.new(configs, mapping_type)
  local Window = require('vfiler/extensions/views/window')
  return core.inherit(Floating, Window, configs, mapping_type)
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
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, texts)
end

function Floating:_on_layout_option(name, texts)
  -- calculate min width and height
  local layout = {
    minwidth = 1,
    minheight = 1,
  }

  local floating = core.deepcopy(self.configs.floating)
  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  if name and #name > 0 then
    -- '2' is space width
    floating.minwidth = math.max(#name + 2, floating.minwidth)
  end

  -- position
  layout.relative = floating.relative and 'win' or 'editor'

  -- decide width and height
  if floating.minwidth then
    layout.minwidth = self:_winvalue(wwidth, floating.minwidth)
  end
  if floating.minheight then
    layout.minheight = self:_winvalue(wheight, floating.minheight)
  end

  -- adjust width: match to the top
  layout.width = self:_winwidth(
    wwidth, floating.width or 'auto', layout.minwidth, wwidth, texts
    )
  layout.height = self:_winheight(
    wheight, floating.height or 'auto', layout.minheight, wheight, texts
    )

  -- claculate position
  layout.row = math.floor((wheight - layout.height) / 2)
  layout.col = math.floor((wwidth - layout.width) / 2)
  return layout
end

function Floating:_on_open(name, texts, layout)
  local option = {
    border = 'rounded',
    col = layout.col,
    focusable = true,
    height = layout.height,
    noautocmd = false,
    relative = layout.relative,
    row = layout.row,
    width = layout.width,
    zindex = 200,
  }
  if option.relative == 'win' then
    option.win = self.caller_winid
  end

  local listed = self.bufoptions.buflisted and true or false
  local buffer = vim.api.nvim_create_buf(listed, true)
  local winid = vim.api.nvim_open_win(buffer, true, option)

  -- set options
  vim.api.nvim_win_set_option(winid, 'winhighlight', 'Normal:Normal')

  -- open title window
  if name and #name > 0 then
    self:_open_tile(name, option)
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
    option.win = self.caller_winid
  end
  local buffer = vim.api.nvim_create_buf(false, true)
  local window = vim.api.nvim_open_win(buffer, false, option)

  -- set options
  vim.api.nvim_win_set_option(window, 'winhighlight', 'Normal:Constant')
  vim.api.nvim_win_set_option(window, 'cursorline', false)

  -- set title name
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, {title})

  self._title = {
    bufnr = buffer,
    winid = window,
  }
end

return Floating
