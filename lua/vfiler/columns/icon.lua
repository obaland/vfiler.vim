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
  return core.inherit(IconColumn, Column, {
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
end

function IconColumn:get_width(items, width)
  return icon_width
end

function IconColumn:_get_text(item, width)
  local iname
  if item.selected then
    iname = 'selected'
  elseif item.type == 'directory' then
    iname = item.opened and 'opened' or 'closed'
  else
    iname = 'file'
  end
  local icon = IconColumn.configs.icons[iname]
  -- padding spaces
  return icon .. (' '):rep(icon_width - vim.fn.strwidth(icon))
end

function IconColumn:_get_syntax_name(item, width)
  local syntax
  if item.selected then
    syntax = 'selected'
  else
    syntax = item.type
  end
  return syntax
end

return IconColumn
