local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

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
  local self = core.inherit(IconColumn, Column, {
    syntaxes = {
      file = {
        group = 'vfilerBookmarkIcon_File',
        start_mark = 'i@f\\',
        highlight = 'vfilerBookmarkFile',
      },
      directory = {
        group = 'vfilerBookmarkIcon_Directory',
        start_mark = 'i@d\\',
        highlight = 'vfilerBookmarkDirectory',
      },
      category = {
        group = 'vfilerBookmarkIcon_Category',
        start_mark = 'i@c\\',
        highlight = 'vfilerBookmarkCategory',
      },
    },
    end_mark = '\\i@',
  })

  self.icon_width = 0
  for _, icon in pairs(IconColumn.configs) do
    self.icon_width = math.max(self.icon_width, vim.fn.strwidth(icon))
  end
  return self
end

function IconColumn:get_width(items)
  return self.icon_width
end

function IconColumn:_get_text(item, width)
  local iname
  if item.iscategory then
    iname = item.opened and 'opened' or 'closed'
  elseif item.isdirectory then
    iname = 'directory'
  else
    iname = 'file'
  end
  local icon = self.configs[iname]
  return icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon))
end

function IconColumn:_get_syntax_name(item, width)
  local syntax
  if item.iscategory then
    syntax = 'category'
  elseif item.isdirectory then
    syntax = 'directory'
  else
    syntax = 'file'
  end
  return syntax
end

return IconColumn
