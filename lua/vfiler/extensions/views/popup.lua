local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'

local window_mappings = {}

local Popup = {}

function Popup.new(configs, mapping_type)
  local object = core.inherit(Popup, Window, configs)
  object.mapping_type = mapping_type
  object.winid = 0
  return object
end

function Popup:close()
  window_mappings[self.winid] = nil
end

function Popup:open(name, texts)
  local options = {
    filter = 'vfiler#popup#filter',
  }

  --self.winid = vim.fn.popup_create(
  self.winid = vim.fn.popup_menu(
    vim.convert_list(texts),
    vim.convert_table(options)
    )
  local bufnr = vim.fn.winbufnr(self.winid)
  local winnr = vim.fn.bufwinnr(bufnr)

  -- add mappings
  window_mappings[self.winid] = self.mapping_type
  return bufnr
end

function Popup:draw(texts, ...)
end

function Popup._filter(winid, key)
  local type = window_mappings[winid]
  for k, value in pairs(mapping.keymappings) do
    print(k, value)
  end
  local keymappings = mapping.keymappings[type]
  if not keymappings then
    core.error('There is no keymappings.')
    vim.fn.popup_close(winid)
    return false
  end

  local command = keymappings[key]
  if command then
    vim.fn.eval(command)
  end
  print('command', command)
  return true
end

return Popup
