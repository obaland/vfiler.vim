local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local IndentColumn = {}

IndentColumn.configs = {
  icon = '|',
}

function IndentColumn.setup(configs)
  core.table.merge(IndentColumn.configs, configs)
end

function IndentColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(IndentColumn, Column, {
    {
      group = 'vfilerIndent',
      name = 'indent',
      region = {
        start_mark = 'i</',
        end_mark = '/>i',
      },
      highlight = 'vfilerDirectory',
    },
  })
end

function IndentColumn:to_text(item, width)
  local indent = item.level - 1
  if indent <= 0 then
    return {
      string = '',
      width = 0,
    }
  end
  local text = (' '):rep((indent * 2) - 1) .. IndentColumn.configs.icon
  return {
    string = text,
    width = vim.fn.strwidth(text),
    syntax = 'indent',
  }
end

function IndentColumn:get_width(items, width, winid)
  if not items then
    return 0
  end
  local max_level = 0
  for _, item in ipairs(items) do
    if item.level > max_level then
      max_level = item.level
    end
  end
  if max_level == 0 then
    return 0
  end
  local icon_width = vim.fn.strwidth(IndentColumn.configs.icon)
  return ((max_level * 2) - 1) + icon_width
end

return IndentColumn
