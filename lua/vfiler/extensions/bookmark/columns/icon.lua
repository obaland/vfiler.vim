local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local IconColumn = {}

IconColumn.configs = {
  file = ' ',
  directory = ' ',
  closed = '+',
  opened = '-',
  unknown = '?',
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
      unknown = {
        group = 'vfilerBookmarkIcon_Unknown',
        start_mark = 'i@u\\',
        highlight = 'vfilerBookmarkUnknown',
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
  local key
  if item.type == 'category' then
    key = item.opened and 'opened' or 'closed'
  else
    key = item.type
  end
  local icon = self.configs[key]
  return icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon))
end

function IconColumn:_get_syntax_name(item, width)
  return item.type
end

return IconColumn
