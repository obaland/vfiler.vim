local core = require('vfiler/libs/core')

local ModeColumn = {}

function ModeColumn.new()
  local end_mark = '/>m'

  local Column = require('vfiler/columns/column')
  return core.inherit(ModeColumn, Column, {
    {
      group = 'vfilerMode_File',
      name = 'file',
      region = {
        start_mark = 'm..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerFile',
    },
    {
      group = 'vfilerMode_Directory',
      name = 'directory',
      region = {
        start_mark = 'm.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerDirectory',
    },
    {
      group = 'vfilerMode_Link',
      name = 'link',
      region = {
        start_mark = 'm.~</',
        end_mark = end_mark,
      },
      highlight = 'vfilerLink',
    },
    {
      group = 'vfilerMode_Executable',
      name = 'executable',
      region = {
        start_mark = 'm.*</',
        end_mark = end_mark,
      },
      highlight = 'vfilerExecutable',
    },
    {
      group = 'vfilerMode_Hidden',
      name = 'hidden',
      region = {
        start_mark = 'm._</',
        end_mark = end_mark,
      },
      highlight = 'vfilerHidden',
    },
  })
end

function ModeColumn:to_text(item, width)
  local syntax
  if item.name:sub(1, 1) == '.' then
    syntax = 'hidden'
  elseif item.mode:sub(3, 3) == 'x' then
    syntax = 'executable'
  elseif item.link then
    syntax = 'link'
  else
    syntax = item.type
  end

  local mode = '-'
  if item.link then
    mode = 'l'
  elseif item.type == 'directory' then
    mode = 'd'
  end
  return {
    string = mode .. item.mode:sub(1, 3),
    width = 4,
    syntax = syntax,
  }
end

function ModeColumn:get_width(items, width, winid)
  return 4
end

return ModeColumn
