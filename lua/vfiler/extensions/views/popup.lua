local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Popup = {}

function Popup.new(options)
  local Window = require('vfiler/extensions/views/window')
  return core.inherit(Popup, Window, options)
end

function Popup:close()
  if self.winid > 0 then
    -- Note: If you do not run it from the calling window, you will get an error
    vim.fn.win_execute(
      self.caller_winid, ('call popup_close(%d)'):format(self.winid)
      )
    vim.fn['vfiler#popup#unmap'](self.winid)
  end
end

function Popup:define_mapping(mappings, funcstr)
  local keys = {}
  for key, _ in pairs(mappings) do
    table.insert(keys, key)
  end
  vim.fn['vfiler#popup#map'](self.winid, vim.to_vimlist(keys), funcstr)
  return core.table.copy(mappings)
end

function Popup:draw(name, texts)
  -- Nothing to do
end

function Popup:_on_layout_option(name, texts)
  local floating = self.options.floating
  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  local options = {
    minwidth = 1,
    minheight = 1,
    line = 0,
    col = 0,
  }

  -- decide width and height
  if floating.minwidth then
    options.minwidth = self:_winvalue(wwidth, floating.minwidth)
  end
  if floating.minheight then
    options.minheight = self:_winvalue(wheight, floating.minheight)
  end

  -- decide position
  if floating.relative then
    options.pos = 'topleft'

    local width = self:_winwidth(
      wwidth, floating.width or 'auto', options.minwidth, wwidth, texts
      )

    local height = self:_winheight(
      wheight, floating.height or 'auto', options.minheight, wheight, texts
      )

    local screen_pos = vim.fn.win_screenpos(self.caller_winid)
    local x = screen_pos[2]
    local y = screen_pos[1]
    options.line = y + math.floor(wheight - ((height / 2) + (wheight / 2)))
    options.col = x + math.floor(wwidth - ((width / 2) + (wwidth / 2)))
  else
    options.pos = 'center'
  end
  return options
end

function Popup:_on_open(name, texts, options)
  local popup_options = {
    border = vim.to_vimlist({1, 1, 1, 1}),
    col = options.col,
    cursorline = true,
    drag = false,
    filter = 'vfiler#popup#filter',
    line = options.line,
    mapping = false,
    minheight = options.minheight,
    minwidth = options.minwidth,
    pos = options.pos,
    title = name,
    wrap = false,
    zindex = 200,
    width = options.width,
  }

  return vim.fn.popup_create(
    vim.to_vimlist(texts), vim.to_vimdict(popup_options)
    )
end

return Popup
