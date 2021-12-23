local core = require('vfiler/core')
local vim = require('vfiler/vim')

local IconColumn = {}

IconColumn.configs = {
  file = ' ',
  directory = ' ',
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
      file = {
        group = 'vfilerBookmark_IconFile',
        start_mark = 'i@f\\',
        highlight = 'vfilerBookmark_File',
      },
      directory = {
        group = 'vfilerBookmark_IconDirectory',
        start_mark = 'i@d\\',
        highlight = 'vfilerBookmark_Directory',
      },
      category = {
        group = 'vfilerBookmark_IconCategory',
        start_mark = 'i@c\\',
        highlight = 'vfilerBookmark_Category',
      },
    },
    end_mark = '\\i@',
    ignore_group = 'vfilerBookmark_IconIgnore',
  }
  return self
end

function IconColumn:get_text(item, width)
  local iname, sname
  if item.iscategory then
    iname = item.opened and 'opened' or 'closed'
    sname = 'category'
  elseif item.isdirectory then
    iname = 'directory'
    sname = 'directory'
  else
    iname = 'file'
    sname = 'file'
  end
  local icon = self.configs[iname]
  icon = icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon))
  return self._syntax:surround_text(sname, icon)
end

function IconColumn:get_width(items)
  return self.icon_width
end

return IconColumn
