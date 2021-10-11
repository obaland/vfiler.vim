local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Border = require 'vfiler/extensions/views/border'

local Floating = {}

function Floating.new(configs, mapping_type)
  local Window = require('vfiler/extensions/views/window')
  local object = core.inherit(Floating, Window, configs, mapping_type)
  object._border = Border.new()
  return object
end

function Floating:close()
  self._border:close()
  if self.winid > 0 then
    vim.api.nvim_win_close(self.winid, true)
  end
end

function Floating:draw(texts, ...)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, texts)
end

function Floating:_on_apply_options(winid)
  vim.set_buf_options(self.bufoptions)
  vim.set_win_options(self.winoptions)

  -- set fixed option
  vim.api.nvim_win_set_option(winid, 'number', false)
end

function Floating:_on_layout_option(name, texts)
  local border = self._border
  local bwidth = self._border_width
  local title_width = vim.fn.strwidth(name)

  local floating = self.configs.floating
  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  -- calculate min width and height
  local layout = {
    minwidth = 4,
    minheight = 1,
  }

  -- position
  layout.relative = floating.relative and 'win' or 'editor'

  -- decide width and height
  if floating.minwidth then
    layout.minwidth = self:_winvalue(wwidth, floating.minwidth)
  end
  if floating.minheight then
    layout.minheight = self:_winvalue(wheight, floating.minheight)
  end

  -- adjust width: match to the top border
  layout.width = self:_winwidth(
    wwidth, floating.width or 'auto', layout.minwidth, wwidth, texts
    )
  layout.height = self:_winheight(
    wheight, floating.height or 'auto', layout.minheight, wheight, texts
    )

  -- decide position
  layout.row = math.floor((wheight - layout.height) / 2)
  layout.col = math.floor((wwidth - layout.width) / 2)
  return layout
end

function Floating:_on_open(name, texts, layout_option)
  local options = {
    col = layout_option.col,
    focusable = true,
    height = layout_option.height,
    noautocmd = false,
    relative = layout_option.relative,
    row = layout_option.row,
    width = layout_option.width,
    win = self.caller_winid,
    zindex = 200,
  }

  local border_configs = {
    title = name,
    content = options,
  }
  self._border:open(border_configs)

  -- overwrite the content
  options.width = self._border.content.width
  options.col = self._border.content.col

  local listed = self.bufoptions.buflisted and true or false
  local buffer = vim.api.nvim_create_buf(listed, true)
  return vim.api.nvim_open_win(buffer, true, options)
end

return Floating
