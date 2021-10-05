local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Window = require 'vfiler/extensions/views/window'

local Extension = require 'vfiler/extensions/extension'
local ExtensionList = {}

mapping.setup {
  list = {
    ['q'] = [[:lua require'vfiler/extensions/list/action'.do_action('quit')<CR>]],
    ['<CR>'] = [[:lua require'vfiler/extensions/list/action'.do_action('select')<CR>]],
    ['<ESC>'] = [[:lua require'vfiler/extensions/list/action'.do_action('quit')<CR>]],
  },
}

local function number_of_digit(value)
  local digit = 1
  while math.floor(value / (10 * digit)) > 0 do
    digit = digit + 1
    value = value / 10
  end
  return digit
end

function ExtensionList.new(name, context)
  -- create view
  local layout = config.configs.layout
  local view = Window.new(layout)
  view:set_buf_options {
    bufhidden = 'hide',
    buflisted = false,
    buftype = 'nofile',
    filetype = 'vfiler_extension_list',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
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

function ExtensionList:_on_mapping()
  mapping.define('list')
end

function ExtensionList:_on_get_texts(items)
  local num_items = #items
  local digit = number_of_digit(num_items)

  local texts = {}
  for i, item in ipairs(items) do
    local text = ('%' .. tostring(digit) .. 'd: %s'):format(i, item)
    table.insert(texts, text)
  end
  return texts
end

function ExtensionList:_on_draw(texts)
  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)

  local statusline = ([[vfiler/%s (%d)]]):format(self.name, #texts)
  self.view:draw(texts, statusline)

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  -- syntax
  local syntax_name = 'vfilerExtensionList_Number'
  local syntax_commands = {
    core.syntax_clear_command({syntax_name}),
    core.syntax_match_command(syntax_name, [[^\s*\d\+:\s\+]]),
    core.link_highlight_command(syntax_name, 'Constant'),
  }
  vim.commands(syntax_commands)
end

return ExtensionList
