local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Extension = require 'vfiler/extensions/extension'
local ExtensionList = {}

mapping.setup {
  list = {
    ['q'] = [[:lua require'vfiler/extensions/list/action'.quit()<CR>]],
    ['<CR>'] = [[:lua require'vfiler/extensions/list/action'.select()<CR>]],
    ['<ESC>'] = [[:lua require'vfiler/extensions/list/action'.quit()<CR>]],
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

function Extension:_on_set_buf_option()
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
  mapping.define('list')
end

function Extension:_on_draw(lines)
  local num_lines = #lines
  local digit = number_of_digit(num_lines)

  vim.set_buf_option('modifiable', true)
  vim.set_buf_option('readonly', false)
  vim.command('silent %delete _')

  local max_width = 0
  for i, line in ipairs(lines) do
    local text = ('%' .. tostring(digit) .. 'd: %s'):format(i, line)
    local width = vim.fn.strwidth(text)
    if width > max_width then
      max_width = width
    end
    vim.fn.setline(i, text)
  end

  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('readonly', true)

  -- display status line
  vim.set_win_option(
    'statusline', ([[vfiler/%s (%d)]]):format(self.name, num_lines)
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

  return num_lines, max_width
end

return ExtensionList
