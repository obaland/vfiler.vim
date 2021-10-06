local core = require 'vfiler/core'

local Column = require 'vfiler/columns/column'

local HeaderColumn = {}

function HeaderColumn.new()
  return core.inherit(HeaderColumn, Column, 'header')
end

function HeaderColumn:get_text(context, lnum, width)
  return '[path] ' .. context.path
end

function HeaderColumn:syntaxes()
  local group_name = 'vfilerHeader'
  return {
    core.syntax_clear_command({group_name}),
    core.syntax_match_command(group_name, '\\%1l.*', {})
  }
end

function HeaderColumn:highlights()
  return {core.link_highlight_command('vfilerHeader', 'Statement')}
end

return HeaderColumn
