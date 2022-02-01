local core = require('vfiler/libs/core')

local ModeColumn = {}

function ModeColumn.new()
  local Column = require('vfiler/columns/column')
  return core.inherit(ModeColumn, Column, {
    syntaxes = {
      executable = {
        group = 'vfilerMode_Executable',
        start_mark = 'm@e\\',
        highlight = 'vfilerExecutable',
      },
      directory = {
        group = 'vfilerMode_Directory',
        start_mark = 'm@d\\',
        highlight = 'vfilerDirectory',
      },
      link = {
        group = 'vfilerMode_Link',
        start_mark = 'm@l\\',
        highlight = 'vfilerLink',
      },
      file = {
        group = 'vfilerMode_File',
        start_mark = 'm@f\\',
        highlight = 'vfilerFile',
      },
      hidden = {
        group = 'vfilerMode_Hidden',
        start_mark = 'm@h\\',
        highlight = 'vfilerHidden',
      },
    },
    end_mark = '\\m@',
  })
end

function ModeColumn:get_width(items, width)
  return 4
end

function ModeColumn:_get_text(item, width)
  local mode = '-'
  if item.is_link then
    mode = 'l'
  elseif item.is_directory then
    mode = 'd'
  end
  return mode .. item.mode:sub(1, 3)
end

function ModeColumn:_get_syntax_name(item, width)
  local key
  if item.name:sub(1, 1) == '.' then
    key = 'hidden'
  elseif item.mode:sub(3, 3) == 'x' then
    key = 'executable'
  elseif item.is_link then
    key = 'link'
  elseif item.is_directory then
    key = 'directory'
  else
    key = 'file'
  end
  return key
end

return ModeColumn
