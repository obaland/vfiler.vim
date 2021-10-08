local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'
local Popup = {}

function Popup.new(configs, mapping_type)
  return core.inherit(Popup, Window, configs, mapping_type)
end

function Popup:close()
  if self.winid > 0 then
    -- Note: If you do not run it from the calling window, you will get an error
    vim.fn.win_execute(
      self.src_winid, ('call popup_close(%d)'):format(self.winid)
      )
    vim.fn['vfiler#popup#unmap'](self.winid)
  end
end

function Popup:open(name, texts)
  local laytout = self:_get_layout_option(texts)
  local options = {
    cursorline = true,
    filter = 'vfiler#popup#filter',
    drag = false,
    mapping = false,
    pos = 'center',
    title = self:_get_name(name),
    wrap = false,
    zindex = 200,
  }

  self.winid = vim.fn.popup_create(
    vim.convert_list(texts),
    vim.convert_table(options)
    )
  self.bufnr = vim.fn.winbufnr(self.winid)

  -- set window option
  vim.fn.win_execute(self.winid, 'setlocal number')

  -- key mappings
  vim.fn['vfiler#popup#map'](
    self.winid,
    vim.convert_table(mapping.keymappings[self.mapping_type])
    )
  return self.winid
end

function Popup:draw(texts, ...)
end

function Popup:_get_layout_option(texts)
  local floating = self.configs.floating
  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  local layout = {
    width = 'auto',
    height = 'auto',
    minwidth = '8',
    minheight = '4',
    pos = 'center',
    line = 0,
    col = 0,
  }

  -- decide width and height
  if floating.width then
    layout.width = self:_winwidth(floating.width, wwidth, texts)
  end
  if floating.height then
    layout.height = self:_winheight(floating.height, wheight, texts)
  end
  if floating.minwidth then
    layout.minwidth = self:_winwidth(floating.width, wwidth, texts)
  end
  if floating.minheight then
    layout.minheight = self:_winheight(floating.height, wheight, texts)
  end

  -- decide position
  if floating.relative then
    layout.pos = 'center'
  else
    layout.pos = 'topleft'
  end

  return layout
end

return Popup
