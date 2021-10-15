local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Popup = {}

local bordercahrs = {
  rounded = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'},
}

function Popup.new(configs, mapping_type)
  local Window = require('vfiler/extensions/views/window')
  local object = core.inherit(Popup, Window, configs, mapping_type)
  object._borderchars = bordercahrs.rounded
  return object
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

function Popup:draw(texts, ...)
  -- Nothng to do
end

function Popup:_on_apply_options(winid)
  -- set buffer options
  if self.bufoptions then
    for key, value in pairs(self.bufoptions) do
      vim.fn.win_execute(
        winid, vim.command_set_option('setlocal', key, value)
        )
    end
  end

  -- set window options
  if self.winoptions then
    for key, value in pairs(self.winoptions) do
      -- 'number' is omitted as a special option
      if key ~= 'number' then
        vim.fn.win_execute(
          winid, vim.command_set_option('setlocal', key, value)
          )
      end
    end
  end
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
    minwidth = 8,
    minheight = 4,
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

function Popup:_on_open(name, texts, layout_option)
  local options = {
    border = vim.vim_list({1, 1, 1, 1}),
    --borderchars = vim.vim_list(self._borderchars),
    col = layout_option.col,
    cursorline = true,
    drag = false,
    filter = 'vfiler#popup#filter',
    line = layout_option.line,
    mapping = false,
    minheight = layout_option.minheight,
    minwidth = layout_option.minwidth,
    pos = layout_option.pos,
    title = name,
    wrap = false,
    zindex = 200,
    width = layout_option.width,
  }

  local winid = vim.fn.popup_create(
    vim.vim_list(texts), vim.vim_dict(options)
    )

  -- TODO: border line color

  -- key mappings
  vim.fn['vfiler#popup#map'](
    winid,
    vim.vim_dict(mapping.keymappings[self.mapping_type])
    )
  return winid
end

return Popup
