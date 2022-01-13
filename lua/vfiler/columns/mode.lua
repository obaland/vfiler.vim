local core = require('vfiler/core')

local ModeColumn = {}

function ModeColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(ModeColumn, Column)

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new({
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
  return self
end

function ModeColumn:get_text(item, width)
  local mode = '-'
  if item.islink then
    mode = 'l'
  elseif item.isdirectory then
    mode = 'd'
  end
  mode = mode .. item.mode:sub(1, 3)

  local key = 'file'
  if item.name:sub(1, 1) == '.' then
    key = 'hidden'
  elseif mode:sub(#mode, #mode) == 'x' then
    key = 'executable'
  elseif item.islink then
    key = 'link'
  elseif item.isdirectory then
    key = 'directory'
  end
  return self._syntax:surround_text(key, mode)
end

function ModeColumn:get_width(items, width)
  return 4
end

return ModeColumn
