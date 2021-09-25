local core = require 'vfiler/core'

local Column = require 'vfiler/columns/column'

local HeaderColumn = {}

function HeaderColumn.new()
  return core.inherit(HeaderColumn, Column, 'header')
end

function HeaderColumn:get_text(context, lnum, width)
  return '[path]:' .. context.path
end

function HeaderColumn:syntaxes()
  return {core.syntax_match_command('vfilerHeader', '\\%1l.*', {})}
end

function HeaderColumn:highlights()
  return {core.link_highlight_command('vfilerHeader', 'Statement')}
end

return HeaderColumn
