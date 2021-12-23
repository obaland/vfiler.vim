local core = require('vfiler/core')
local vim = require('vfiler/vim')

local NameColumn = {}

function NameColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(NameColumn, Column, 'name')
  self.stretch = true

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new {
    syntaxes = {
      category = {
        group = 'vfilerBookmark_NameCategory',
        start_mark = 'n@c\\',
        highlight = 'vfilerBookmark_Category',
      },
      file = {
        group = 'vfilerBookmark_NameFile',
        start_mark = 'n@f\\',
        highlight = 'vfilerBookmark_File',
      },
      directory = {
        group = 'vfilerBookmark_NameDirectory',
        start_mark = 'n@d\\',
        highlight = 'vfilerBookmark_Directory',
      },
      link = {
        group = 'vfilerBookmark_NameLink',
        start_mark = 'n@l\\',
        highlight = 'vfilerBookmark_Link',
      },
    },
    end_mark = '\\n@',
    ignore_group = 'vfilerBookmark_NameIgnore',
  }
  return self
end

function NameColumn:get_text(item, width)
  local name = item.name
  local syntax_name = ''
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
