local action = require 'vfiler/extensions/menu/action'
local config = require 'vfiler/extensions/menu/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local ExtensionMenu = {}

config.setup {
  mappings = {
    ['k']     = action.loop_cursor_up,
    ['j']     = action.loop_cursor_down,
    ['q']     = action.quit,
    ['<CR>']  = action.select,
    ['<ESC>'] = action.quit,
  },

  events = {
    BufWinLeave = action.quit,
  },
}

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
  vim.set_local_option('modifiable', true)
  vim.set_local_option('readonly', false)

  self.view:draw(self.name, texts)

  vim.set_local_option('modifiable', false)
  vim.set_local_option('readonly', true)
end

return ExtensionMenu
