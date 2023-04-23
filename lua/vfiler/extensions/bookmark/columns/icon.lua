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
  local end_mark = '/>c'

  local Column = require('vfiler/columns/column')
  local self = core.inherit(IconColumn, Column, {
    {
      group = 'vfilerBookmarkIcon_File',
      name = 'file',
      region = {
        start_mark = 'c..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkFile',
    },
    {
      group = 'vfilerBookmarkIcon_Directory',
      name = 'directory',
      region = {
        start_mark = 'c.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkDirectory',
    },
    {
      group = 'vfilerBookmarkIcon_Category',
      name = 'category',
      region = {
        start_mark = 'c._</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkCategory',
    },
    {
      group = 'vfilerBookmarkIcon_Unknown',
      name = 'unknown',
      region = {
        start_mark = 'c.?</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkUnknown',
    },
  })

  self.icon_width = 0
  for _, icon in pairs(IconColumn.configs) do
    self.icon_width = math.max(self.icon_width, vim.fn.strwidth(icon))
  end
  return self
end

function IconColumn:get_text(item, width)
  local key
  if item.type == 'category' then
    key = item.opened and 'opened' or 'closed'
  else
    key = item.type
  end
  local icon = self.configs[key]
  local text = icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon))
  return self:surround_text(item.type, text), self.icon_width
end

function IconColumn:get_width(items)
  return self.icon_width
end

return IconColumn
