local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local IndentColumn = {}

IndentColumn.configs = {
  icon = '|',
}

function IndentColumn.setup(configs)
  core.table.merge(IndentColumn.configs, configs)
end

function IndentColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(IndentColumn, Column, 'indent')

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new {
    syntaxes = {
      indent = {
        group = 'vfilerIndent',
        start_mark = 'I@\\',
        highlight = 'vfilerDirectory',
      },
    },
    end_mark = '\\@I',
    ignore_group = 'vfilerIndent_Ignore',
  }
  return self
end

function IndentColumn:get_text(item, width)
  local indent = item.level - 1
  if indent > 0 then
    return self._syntax:surround_text(
      'indent', (' '):rep((indent * 2) - 1) .. self.configs.icon
    )
  end
  return '', 0
end

function IndentColumn:get_width(items, width)
  local max_level = 0
  for _, item in ipairs(items) do
    if item.level > max_level then
      max_level = item.level
    end
  end
  if max_level == 0 then
    return 0
  end
  return ((max_level * 2) - 1) + vim.fn.strwidth(self.configs.icon)
end

return IndentColumn
