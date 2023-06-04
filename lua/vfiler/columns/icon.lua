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

  local end_mark = '/>c'
  return core.inherit(IconColumn, Column, {
    {
      group = 'vfilerIcon_Selected',
      name = 'selected',
      region = {
        start_mark = 'c.*</',
        end_mark = end_mark,
      },
      highlight = 'vfilerSelected',
    },
    {
      group = 'vfilerIcon_File',
      name = 'file',
      region = {
        start_mark = 'c..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerFile',
    },
    {
      group = 'vfilerIcon_Closed',
      name = 'closed',
      region = {
        start_mark = 'c.+</',
        end_mark = end_mark,
      },
      highlight = 'vfilerDirectory',
    },
    {
      group = 'vfilerIcon_Opened',
      name = 'opened',
      region = {
        start_mark = 'c.-</',
        end_mark = end_mark,
      },
      highlight = 'vfilerDirectory',
    },
  })
end

function IconColumn:to_text(item, width)
  local syntax
  if item.selected then
    syntax = 'selected'
  elseif item.type == 'directory' then
    syntax = item.opened and 'opened' or 'closed'
  else
    syntax = 'file'
  end
  local icon = IconColumn.configs.icons[syntax]
  -- padding spaces
  local text = icon .. (' '):rep(icon_width - vim.fn.strwidth(icon))
  return {
    string = text,
    width = vim.fn.strwidth(text),
    syntax = syntax,
  }
end

function IconColumn:get_width(items, width, winid)
  return icon_width
end

return IconColumn
