local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Column = require 'vfiler/columns/column'
local Syntax = require 'vfiler/columns/syntax'

local IconColumn = {}

function IconColumn.new()
  local self = core.inherit(IconColumn, Column, 'icon')
  self.selected = '*'
  self.file = ' '
  self.closed_directory = '+'
  self.opened_directory = '-'

  self._syntax = Syntax.new {
    syntaxes = {
      selected = {
        group = 'vfilerIcon_Selected',
        start_mark = 'i@s\\',
        highlight = 'vfilerSelected',
      },
      file = {
        group = 'vfilerIcon_File',
        start_mark = 'i@f\\',
        highlight = 'vfilerFile',
      },
      directory = {
        group = 'vfilerIcon_Directory',
        start_mark = 'i@d\\',
        highlight = 'vfilerDirectory',
      },
    },
    end_mark = '\\i@',
    ignore_group = 'vfilerIcon_Ignore',
  }
  return self
end

function IconColumn:get_text(context, lnum, width)
  local item = context:get_item(lnum)
  local icon_name, syntax_name
  if item.selected then
    icon_name = 'selected'
    syntax_name = 'selected'
  elseif item.isdirectory then
    icon_name = item.opened and 'opened_directory' or 'closed_directory'
    syntax_name = 'directory'
  else
    icon_name = 'file'
    syntax_name = 'file'
  end
  return self._syntax:surround_text(syntax_name, self[icon_name])
end

function IconColumn:get_width(context, width)
  local icons = {
    self.selected,
    self.file,
    self.closed_directory,
    self.opened_directory,
  }
  -- decide width
  local icon_width = -1
  for _, icon in pairs(icons) do
    icon_width = math.max(icon_width, vim.fn.strwidth(icon))
  end
  return icon_width
end

function IconColumn:highlights()
  return self._syntax:highlights()
end

function IconColumn:syntaxes()
  return self._syntax:syntaxes()
end

return IconColumn
