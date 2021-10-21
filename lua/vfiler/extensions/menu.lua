local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local ExtensionMenu = {}

local function _action(name, ...)
  local func = [[:lua require('vfiler/extensions/menu/action').do_action]]
  if ... then
    func = func .. ([[('%s', %s)]]):format(name, ...)
  else
    func = func .. ([[('%s')]]):format(name)
  end
  return func
end

mapping.setup {
  menu = {
    ['k']     = _action('move_cursor_up', 'true'),
    ['j']     = _action('move_cursor_down', 'true'),
    ['q']     = _action('quit'),
    ['<CR>']  = _action('select'),
    ['<ESC>'] = _action('quit'),
  },
}

function ExtensionMenu.new(name, context)
  local Extension = require('vfiler/extensions/extension')
  local view = Extension.create_view(config.configs.layout, 'menu')
  view:set_buf_options {
    filetype = 'vfiler_extension_menu',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  view:set_win_options {
    number = true,
  }
  return core.inherit(ExtensionMenu, Extension, name, context, view, config)
end

function ExtensionMenu:select()
  local item = self.items[vim.fn.line('.')]

  self:quit()

  if self.on_selected then
    self.on_selected(self.context, item)
  end
  return item
end

function ExtensionMenu:_on_get_texts(items)
  return items
end

function ExtensionMenu:_on_draw(texts)
  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)

  self.view:draw(self.name, texts)

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)
end

return ExtensionMenu
