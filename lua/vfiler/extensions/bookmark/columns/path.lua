local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local PathColumn = {}

local function to_text(item)
  if not item.path then
    return ''
  end

  local text = item.path
  if not core.path.exists(item.path) then
    text = ('[Not exist] - %s'):format(item.path)
  end
  return ('(%s)'):format(text)
end

function PathColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(PathColumn, Column, {
    syntaxes = {
      path = {
        group = 'vfilerBookmarkItem_Path',
        start_mark = 'p@p\\',
        highlight = 'vfilerBookmarkPath',
      },
      notexist = {
        group = 'vfilerBookmarkItem_NotExist',
        start_mark = 'p@n\\',
        highlight = 'vfilerBookmarkWarning',
      },
    },
    end_mark = '\\p@',
  })
end

function PathColumn:get_width(items)
  local max = 0
  for _, item in ipairs(items) do
    max = math.max(max, vim.fn.strwidth(to_text(item)))
  end
  return max
end

function PathColumn:_get_text(item)
  return item.path and to_text(item) or ''
end

function PathColumn:_get_syntax_name(item)
  return core.path.exists(item.path) and 'path' or 'notexist'
end

return PathColumn
