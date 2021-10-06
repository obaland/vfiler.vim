local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'

local window_mappings = {}

local Popup = {}

function Popup.new(configs, mapping_type)
  return core.inherit(Popup, Window, configs, mapping_type)
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
  self.bufnr = vim.fn.winbufnr(self.winid)

  -- add mappings
  window_mappings[self.winid] = self.mapping_type
  return self.bufnr
end

function Popup:draw(texts, ...)
end

function Popup._filter(winid, key)
  local type = window_mappings[winid]
  local keymappings = mapping.keymappings[type]
  if not keymappings then
    core.error('There is no keymappings.')
    vim.fn.popup_close(winid)
    return false
  end

  local command = keymappings[key]
  if command then
    vim.fn.execute(command)
  end
  return true
end

return Popup
