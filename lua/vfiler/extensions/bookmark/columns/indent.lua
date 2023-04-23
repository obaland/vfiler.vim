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
      group = 'vfilerBookmarkIndent',
      name = 'indent',
      region = {
        start_mark = 'i.</',
        end_mark = '/>i',
      },
      highlight = 'vfilerBookmarkCategory',
    },
  })
end

function IndentColumn:get_text(item, width)
  local indent = item.level - 1
  if indent <= 0 then
    return '', 0
  end
  local text = (' '):rep((indent * 2) - 1) .. self.configs.icon
  return self:surround_text('indent', text), vim.fn.strwidth(text)
end

function IndentColumn:get_width(items)
  -- "1" is white space for indent
  return 1 + vim.fn.strwidth(self.configs.icon)
end

return IndentColumn
