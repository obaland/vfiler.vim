local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

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

function ExtensionList.new(name, ...)
  return core.inherit(ExtensionList, Extension, name, ...)
end

function ExtensionList:select()
  if self.on_selected then
    self.on_selected('selected')
  end
  return 'selected text'
end

function ExtensionList:_on_set_buf_option()
  vim.set_buf_option('bufhidden', 'hide')
  vim.set_buf_option('buflisted', false)
  vim.set_buf_option('buftype', 'nofile')
  vim.set_buf_option('filetype', 'vfiler_extension_list')
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('modified', false)
  vim.set_buf_option('readonly', false)
  vim.set_buf_option('swapfile', false)
end

function ExtensionList:_on_mapping()
  print('come.')
  mapping.define('list')
end

function Extension:_on_get_texts()
  local num_items = #self.items
  local digit = number_of_digit(num_items)

  local texts = {}
  for i, item in ipairs(self.items) do
    local text = ('%' .. tostring(digit) .. 'd: %s'):format(i, item)
    table.insert(texts, text)
  end
  return texts
end

function Extension:_on_draw(texts, winwidth, winheight)
  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')

  for i, text in ipairs(texts) do
    vim.fn.setline(i, text)
  end

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  -- display status line
  vim.set_win_option(
    'statusline', ([[vfiler/%s (%d)]]):format(self.name, #texts)
  )

  -- syntax
  local syntax_name = 'vfilerExtensionList_Number'
  local syntax_commands = {}
  table.insert(
    syntax_commands,
    core.syntax_match_command(syntax_name, [[^\s*\d\+:\s\+]])
  )
  table.insert(
    syntax_commands,
    core.link_highlight_command(syntax_name, 'Constant')
  )
  vim.commands(syntax_commands)
end

return ExtensionList
