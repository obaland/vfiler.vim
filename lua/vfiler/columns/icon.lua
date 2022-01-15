local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local IconColumn = {}

IconColumn.configs = {
  icons = {
    selected = '*',
    file = ' ',
    closed = '+',
    opened = '-',
  },
}

local function get_icon_width(icons)
  local width = 0
  for _, icon in ipairs(icons) do
    width = math.max(vim.fn.strwidth(icon), width)
  end
  return width
end

local icon_width = get_icon_width(IconColumn.configs.icons)

function IconColumn.setup(configs)
  core.table.merge(IconColumn.configs, configs)
  icon_width = get_icon_width(IconColumn.configs.icons)
end

function IconColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(IconColumn, Column)

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new({
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
  })
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
  local icon = IconColumn.configs.icons[iname]
  icon = icon .. (' '):rep(icon_width - vim.fn.strwidth(icon))
  return self._syntax:surround_text(sname, icon)
end

function IconColumn:get_width(items, width)
  return icon_width
end

return IconColumn
