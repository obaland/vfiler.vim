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
    syntaxes = {
      indent = {
        group = 'vfilerIndent',
        start_mark = 'I@\\',
        highlight = 'vfilerDirectory',
      },
    },
    end_mark = '\\@I',
  })
end

function IndentColumn:get_width(items, width)
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

function IndentColumn:_get_text(item, width)
  local indent = item.level - 1
  if indent <= 0 then
    return ''
  end
  return (' '):rep((indent * 2) - 1) .. IndentColumn.configs.icon
end

function IndentColumn:_get_syntax_name(item, width)
  return 'indent'
end

return IndentColumn
