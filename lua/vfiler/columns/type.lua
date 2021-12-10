local core = require('vfiler/core')

local TypeColumn = {}

function TypeColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(TypeColumn, Column, 'type')

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new {
    syntaxes = {
      directory = {
        group = 'vfilerType_Directory',
        start_mark = 'T@d\\',
        highlight = 'vfilerDirectory',
      },
      link = {
        group = 'vfilerType_Link',
        start_mark = 'T@l\\',
        highlight = 'vfilerLink',
      },
      file = {
        group = 'vfilerType_File',
        start_mark = 'T@f\\',
        highlight = 'vfilerFile',
      },
      hidden = {
        group = 'vfilerType_Hidden',
        start_mark = 'T@h\\',
        highlight = 'vfilerHidden',
      },
    },
    end_mark = '\\T@',
    ignore_group = 'vfilerType_Ignore',
  }
  return self
end

function TypeColumn:get_text(item, width)
  local key
  if item.name:sub(1, 1) == '.' then
    key = 'hidden'
  elseif item.islink then
    key = 'link'
  elseif item.isdirectory then
    key = 'directory'
  else
    key = 'file'
  end

  local type
  if item.islink then
    type = '[L]'
  elseif item.isdirectory then
    type = '[D]'
  else
    type = '[F]'
  end
  return self._syntax:surround_text(key, type)
end

function TypeColumn:get_width(items, width)
  return 3
end

return TypeColumn
