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

function IconColumn.new(configs)
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
  self._configs = core.table.copy(configs or IconColumn.configs)
  for _, icon in pairs(self._configs) do
    self.icon_width = math.max(self.icon_width, vim.fn.strwidth(icon))
  end
  return self
end

function IconColumn:to_text(item, width)
  local key
  if item.type == 'category' then
    key = item.opened and 'opened' or 'closed'
  else
    key = item.type
  end
  local icon = self._configs[key]
  return {
    string = icon .. (' '):rep(self.icon_width - vim.fn.strwidth(icon)),
    width = self.icon_width,
    syntax = item.type,
  }
end

function IconColumn:get_width(items, width, winid)
  return self.icon_width
end

return IconColumn
