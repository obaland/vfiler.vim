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
        group = 'vfilerBookmarkIndent',
        start_mark = 'I@\\',
        highlight = 'vfilerBookmarkCategory',
      },
    },
    end_mark = '\\@I',
  })
end

function IndentColumn:get_width(items)
  -- "1" is white space for indent
  return 1 + vim.fn.strwidth(self.configs.icon)
end

function IndentColumn:_get_text(item, width)
  local indent = item.level - 1
  if indent <= 0 then
    return ''
  end
  return (' '):rep((indent * 2) - 1) .. self.configs.icon
end

function IndentColumn:_get_syntax_name(item, width)
  return 'indent'
end

return IndentColumn
