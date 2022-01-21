local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local NameColumn = {}

function NameColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(NameColumn, Column, 'name')
  self.stretch = true

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new({
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
  return self
end

function NameColumn:get_text(item, width)
  local name = item.name
  local syntax_name
  if item.iscategory then
    syntax_name = 'category'
  elseif item.islink then
    syntax_name = 'link'
  elseif item.isdirectory then
    syntax_name = 'directory'
  else
    syntax_name = 'file'
  end

  return self._syntax:surround_text(syntax_name, name)
end

function NameColumn:get_width(items)
  local max_width = 0
  for _, item in ipairs(items) do
    max_width = math.max(max_width, vim.fn.strwidth(item.name))
  end
  return max_width
end

return NameColumn
