local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local PathColumn = {}

local function to_text(item)
  if not item.path then
    return ''
  end

  local text = item.path
  if not core.path.exists(item.path) then
    text = '[Not exist] - ' .. item.path
  end
  return '(' .. text .. ')'
end

function PathColumn.new()
  local end_mark = '/>p'

  local Column = require('vfiler/columns/column')
  return core.inherit(PathColumn, Column, {
    {
      group = 'vfilerBookmarkItem_Path',
      name = 'path',
      region = {
        start_mark = 'p..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkPath',
    },
    {
      group = 'vfilerBookmarkItem_NotExist',
      name = 'notexist',
      region = {
        start_mark = 'p.?</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkWarning',
    },
  })
end

function PathColumn:get_text(item)
  local syntax = core.path.exists(item.path) and 'path' or 'notexist'
  local text = item.path and to_text(item) or ''
  return self:surround_text(syntax, text), vim.fn.strwidth(text)
end

function PathColumn:get_width(items)
  local max = 0
  for _, item in ipairs(items) do
    max = math.max(max, vim.fn.strwidth(to_text(item)))
  end
  return max
end

return PathColumn
