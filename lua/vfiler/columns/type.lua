local core = require('vfiler/libs/core')

local TypeColumn = {}

function TypeColumn.new()
  local end_mark = '/>t'

  local Column = require('vfiler/columns/column')
  return core.inherit(TypeColumn, Column, {
    {
      group = 'vfilerType_Directory',
      name = 'directory',
      region = {
        start_mark = 't.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerDirectory',
    },
    {
      group = 'vfilerType_Link',
      name = 'link',
      region = {
        start_mark = 't.-</',
        end_mark = end_mark,
      },
      highlight = 'vfilerLink',
    },
    {
      group = 'vfilerType_File',
      name = 'file',
      region = {
        start_mark = 't..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerFile',
    },
    {
      group = 'vfilerType_Hidden',
      name = 'hidden',
      region = {
        start_mark = 't._</',
        end_mark = end_mark,
      },
      highlight = 'vfilerHidden',
    },
  })
end

function TypeColumn:to_text(item, width)
  local syntax
  if item.name:sub(1, 1) == '.' then
    syntax = 'hidden'
  elseif item.link then
    syntax = 'link'
  else
    syntax = item.type
  end

  local type
  if item.link then
    type = '[L]'
  elseif item.type == 'directory' then
    type = '[D]'
  else
    type = '[F]'
  end
  return {
    string = type,
    width = 3,
    syntax = syntax,
  }
end

function TypeColumn:get_width(_, _, _)
  return 3
end

return TypeColumn
