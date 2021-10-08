local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'
local Popup = {}

function Popup.new(configs, mapping_type)
  local object = core.inherit(Popup, Window, configs, mapping_type)
  object.src_winid = vim.fn.win_getid()
  return object
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
  local options = {
    cursorline = true,
    filter = 'vfiler#popup#filter',
    drag = false,
    mapping = false,
    pos = 'center',
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

return Popup
