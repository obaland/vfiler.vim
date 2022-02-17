local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local NameColumn = {}

function NameColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(NameColumn, Column, {
    syntaxes = {
      category = {
        group = 'vfilerBookmarkName_Category',
        start_mark = 'n@c\\',
        highlight = 'vfilerBookmarkCategory',
      },
      file = {
        group = 'vfilerBookmarkName_File',
        start_mark = 'n@f\\',
        highlight = 'vfilerBookmarkFile',
      },
      directory = {
        group = 'vfilerBookmarkName_Directory',
        start_mark = 'n@d\\',
        highlight = 'vfilerBookmarkDirectory',
      },
      link = {
        group = 'vfilerBookmarkName_Link',
        start_mark = 'n@l\\',
        highlight = 'vfilerBookmarkLink',
      },
    },
    end_mark = '\\n@',
  })
end

function NameColumn:get_width(items)
  local max_width = 0
  for _, item in ipairs(items) do
    max_width = math.max(max_width, vim.fn.strwidth(item.name))
  end
  return max_width
end

function NameColumn:_get_text(item, width)
  return item.name
end

function NameColumn:_get_syntax_name(item, width)
  local syntax
  if item.link then
    syntax = 'link'
  else
    syntax = item.type
  end
  return syntax
end

return NameColumn
