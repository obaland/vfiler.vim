local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'

local window_mappings = {}

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
      self.src_winid, 'call popup_close(' .. self.winid .. ')'
      )
    window_mappings[self.winid] = nil
  end
end

function Popup:open(name, texts)
  local options = {
    --filter = 'vfiler#popup#filter',
    --drag = false,
    mapping = true,
    --pos = 'center',
    --wrap = false,
    --zindex = 200,
  }

  self.winid = vim.fn.popup_create(
  --self.winid = vim.fn.popup_menu(
    vim.convert_list(texts),
    vim.convert_table(options)
    )
  self.bufnr = vim.fn.winbufnr(self.winid)

  vim.fn.win_gotoid(self.winid)
  self:_define_mapping()

  print(self.winid, self.bufnr)

  -- add mappings
  window_mappings[self.winid] = self.mapping_type
  return self.winid
end

function Popup:draw(texts, ...)
end

function Popup._filter(winid, key)
  local type = window_mappings[winid]
  local keymappings = mapping.keymappings[type]
  if not keymappings then
    core.error('There is no keymappings.')
    vim.fn.popup_close(winid)
    return true
  end

  print('key:', key, 'code:', key:byte())

  local command = keymappings[key]
  if command then
    vim.fn.win_execute(winid, command)
  end
  return true
end

return Popup
