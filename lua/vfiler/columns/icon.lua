local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local IconColumn = {}

local icon_configs = {
  selected = '*',
  file = ' ',
  closed = '+',
  opened = '-',
}

function IconColumn.setup(configs)
  core.table.merge(icon_configs, configs)
end

function IconColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(IconColumn, Column, 'icon')
  self.selected = '*'
  self.file = ' '
  self.closed_directory = '+'
  self.opened_directory = '-'

  local Syntax = require('vfiler/columns/syntax')
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

function IconColumn:get_text(item, width)
  local iname, sname
  if item.selected then
    iname = 'selected'
    sname = 'selected'
  elseif item.isdirectory then
    iname = item.opened and 'opened' or 'closed'
    sname = 'directory'
  else
    iname = 'file'
    sname = 'file'
  end
  return self._syntax:surround_text(sname, icon_configs[iname])
end

function IconColumn:get_width(items, width)
  -- decide width
  local iwidth = -1
  for _, icon in pairs(icon_configs) do
    iwidth = math.max(iwidth, vim.fn.strwidth(icon))
  end
  return iwidth
end

function IconColumn:highlights()
  return self._syntax:highlights()
end

function IconColumn:syntaxes()
  return self._syntax:syntaxes()
end

return IconColumn
