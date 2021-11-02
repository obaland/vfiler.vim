local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Popup = {}

function Popup.new(configs, mapping_type)
  local Window = require('vfiler/extensions/views/window')
  return core.inherit(Popup, Window, configs, mapping_type)
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

function Popup:draw(name, texts)
  -- Nothing to do
end

function Popup:_on_define_mapping(winid)
  vim.fn['vfiler#popup#map'](
    winid,
    vim.vim_dict(mapping.keymappings[self.mapping_type])
    )
end

function Popup:_on_layout_option(name, texts)
  local floating = self.configs.floating
  local wwidth = vim.fn.winwidth(self.caller_winid)
  local wheight = vim.fn.winheight(self.caller_winid)

  local layout = {
    minwidth = 1,
    minheight = 1,
    line = 0,
    col = 0,
  }

  -- decide width and height
  if floating.minwidth then
    layout.minwidth = self:_winvalue(wwidth, floating.minwidth)
  end
  if floating.minheight then
    layout.minheight = self:_winvalue(wheight, floating.minheight)
  end

  -- decide position
  if floating.relative then
    layout.pos = 'topleft'

    local width = self:_winwidth(
      wwidth, floating.width or 'auto', layout.minwidth, wwidth, texts
      )

    local height = self:_winheight(
      wheight, floating.height or 'auto', layout.minheight, wheight, texts
      )

    local screen_pos = vim.fn.win_screenpos(self.caller_winid)
    local x = screen_pos[2]
    local y = screen_pos[1]
    layout.line = y + math.floor(wheight - ((height / 2) + (wheight / 2)))
    layout.col = x + math.floor(wwidth - ((width / 2) + (wwidth / 2)))
  else
    layout.pos = 'center'
  end
  return layout
end

function Popup:_on_open(name, texts, layout)
  local options = {
    border = vim.vim_list({1, 1, 1, 1}),
    col = layout.col,
    cursorline = true,
    drag = false,
    filter = 'vfiler#popup#filter',
    line = layout.line,
    mapping = false,
    minheight = layout.minheight,
    minwidth = layout.minwidth,
    pos = layout.pos,
    title = name,
    wrap = false,
    zindex = 200,
    width = layout.width,
  }

  local winid = vim.fn.popup_create(
    vim.vim_list(texts), vim.vim_dict(options)
    )

  -- key mappings
  vim.fn['vfiler#popup#map'](
    winid,
    vim.vim_dict(mapping.keymappings[self.mapping_type])
    )
  return winid
end

return Popup
