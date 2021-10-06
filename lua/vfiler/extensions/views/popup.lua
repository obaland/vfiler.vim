local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'

local Popup = {}

function Popup.new(configs)
  local object = core.inherit(Popup, Window, configs)
  object.winid = 0
  return object
end

function Popup:open(name, texts)
  local options = {
    drag = false,
    callback = nil,
  }

  --self.winid = vim.fn.popup_create(
  self.winid = vim.fn.popup_menu(
    vim.convert_list(texts), vim.convert_table(options)
    )
  return vim.fn.winbufnr(self.winid)
end

function Popup:draw(texts, ...)
end

function Popup.callback(winid, key)
  print('callback', winid, key)
end

return Popup
