local core = require('vfiler/core')
local vim = require('vfiler/vim')

local IconColumn = {}

IconColumn.configs = {
  selected = '*',
  file = ' ',
  closed = '+',
  opened = '-',
}

function IconColumn.setup(configs)
  core.table.merge(IconColumn.configs, configs)
end

function IconColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(IconColumn, Column, 'icon')

  self.icon_width = 0
  for _, icon in pairs(IconColumn.configs) do
    self.icon_width = math.max(self.icon_width, vim.fn.strwidth(icon))
  end

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
  local icon = self.configs[iname]
  icon = icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon))
  return self._syntax:surround_text(sname, icon)
end

function IconColumn:get_width(items, width)
  return self.icon_width
end

return IconColumn
