local core = require('vfiler/libs/core')

local TypeColumn = {}

function TypeColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(TypeColumn, Column, {
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
  })
end

function TypeColumn:get_width(items, width)
  return 3
end

function TypeColumn:_get_text(item, width)
  local type
  if item.is_link then
    type = '[L]'
  elseif item.is_directory then
    type = '[D]'
  else
    type = '[F]'
  end
  return type
end

function TypeColumn:_get_syntax_name(item, width)
  local key
  if item.name:sub(1, 1) == '.' then
    key = 'hidden'
  elseif item.is_link then
    key = 'link'
  elseif item.is_directory then
    key = 'directory'
  else
    key = 'file'
  end
  return key
end

return TypeColumn
