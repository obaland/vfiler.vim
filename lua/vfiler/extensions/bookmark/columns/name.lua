local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local NameColumn = {}

function NameColumn.new()
  local end_mark = '/>n'

  local Column = require('vfiler/columns/column')
  return core.inherit(NameColumn, Column, {
    {
      group = 'vfilerBookmarkName_Category',
      name = 'category',
      region = {
        start_mark = 'n._</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkCategory',
    },
    {
      group = 'vfilerBookmarkName_File',
      name = 'file',
      region = {
        start_mark = 'n..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkFile',
    },
    {
      group = 'vfilerBookmarkName_Directory',
      name = 'directory',
      region = {
        start_mark = 'n.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkDirectory',
    },
    {
      group = 'vfilerBookmarkName_Link',
      name = 'link',
      region = {
        start_mark = 'n.~</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkLink',
    },
    {
      group = 'vfilerBookmarkName_Unknown',
      name = 'unknown',
      region = {
        start_mark = 'n.?</',
        end_mark = end_mark,
      },
      highlight = 'vfilerBookmarkUnknown',
    },
  })
end

function NameColumn:get_text(item, width)
  local syntax = item.link and 'link' or item.type
  return self:surround_text(syntax, item.name), vim.fn.strwidth(item.name)
end

function NameColumn:get_width(items)
  local max_width = 0
  for _, item in ipairs(items) do
    max_width = math.max(max_width, vim.fn.strwidth(item.name))
  end
  return max_width
end

return NameColumn
