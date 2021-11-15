local config = require 'vfiler/extensions/menu/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local ExtensionMenu = {}

function ExtensionMenu.new(options)
  local Extension = require('vfiler/extensions/extension')

  local configs = config.configs
  local view = Extension.create_view(configs.options)
  view:set_buf_options {
    filetype = 'vfiler_menu',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  view:set_win_options {
    number = true,
  }

  local object = core.inherit(
    ExtensionMenu, Extension, options.name, view, configs
    )
  object.on_quit = options.on_quit
  object.on_selected = options.on_selected
  return object
end

function ExtensionMenu:select()
  local item = self.items[vim.fn.line('.')]

  self:quit()

  if self.on_selected then
    self.on_selected(item)
  end
  return item
end

function ExtensionMenu:_on_get_texts(items)
  return items
end

function ExtensionMenu:_on_draw(texts)
  local bufnr = self.view.bufnr
  vim.set_buf_option(bufnr, 'modifiable', true)
  vim.set_buf_option(bufnr, 'readonly', false)
  self.view:draw(self.name, texts)
  vim.set_buf_option(bufnr, 'modifiable', false)
  vim.set_buf_option(bufnr, 'readonly', true)
end

return ExtensionMenu
