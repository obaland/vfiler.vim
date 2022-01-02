local core = require('vfiler/core')
local vim = require('vfiler/vim')

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
  local self = core.inherit(PathColumn, Column, 'path')

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new({
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
    ignore_group = 'vfilerBookmarkPath_Ignore',
  })
  return self
end

function PathColumn:get_text(item)
  if not item.path then
    return '', 0
  end
  local syntax
  if core.path.exists(item.path) then
    syntax = 'path'
  else
    syntax = 'notexist'
  end
  return self._syntax:surround_text(syntax, to_text(item))
end

function PathColumn:get_width(items)
  local max = 0
  for _, item in ipairs(items) do
    max = math.max(max, vim.fn.strwidth(to_text(item)))
  end
  return max
end

return PathColumn
