local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local ExtensionMenu = {}

local function _do_action(name, ...)
  local func = [[:lua require('vfiler/extensions/menu/action').do_action]]
  local args = ''
  if ... then
    args = ([[('%s', %s)]]):format(name, ...)
  else
    args = ([[('%s')]]):format(name)
  end
  return func .. args
end

mapping.setup {
  menu = {
    ['k']     = _do_action('move_cursor_up', 'true'),
    ['j']     = _do_action('move_cursor_down', 'true'),
    ['q']     = _do_action('quit'),
    ['<CR>']  = _do_action('select'),
    ['<ESC>'] = _do_action('quit'),
  },
}

function ExtensionMenu.new(options)
  local Extension = require('vfiler/extensions/extension')

  local view = Extension.create_view(config.configs.layout, 'menu')
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
    ExtensionMenu, Extension, options.name, view, config
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
  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)

  self.view:draw(self.name, texts)

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)
end

return ExtensionMenu
