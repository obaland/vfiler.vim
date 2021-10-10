local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local ExtensionList = {}

mapping.setup {
  list = {
    ['k'] = [[:lua require'vfiler/extensions/list/action'.do_action('move_cursor_up', true)]],
    ['j'] = [[:lua require'vfiler/extensions/list/action'.do_action('move_cursor_down', true)]],
    ['q'] = [[:lua require'vfiler/extensions/list/action'.do_action('quit')]],
    ['<CR>'] = [[:lua require'vfiler/extensions/list/action'.do_action('select')]],
    ['<ESC>'] = [[:lua require'vfiler/extensions/list/action'.do_action('quit')]],
    ['gg'] = [[:lua require'vfiler/extensions/list/action'.do_action('quit')]],
  },
}

function ExtensionList.new(name, context)
  local Extension = require('vfiler/extensions/extension')
  local view = Extension.create_view(config.configs.layout, 'list')
  view:set_buf_options {
    filetype = 'vfiler_extension_list',
    modifiable = false,
    modified = false,
    readonly = true,
  }
  return core.inherit(ExtensionList, Extension, name, context, view, config)
end

function ExtensionList:select()
  local item = self.items[vim.fn.line('.')]

  self:quit()

  if self.on_selected then
    self.on_selected(item)
  end
  return item
end

function ExtensionList:_on_get_texts(items)
  return items
end

function ExtensionList:_on_draw(texts)
  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)

  local statusline = ([[vfiler/%s (%d)]]):format(self.name, #texts)
  self.view:draw(texts, statusline)

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)
end

return ExtensionList
