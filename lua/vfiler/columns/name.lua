local core = require('vfiler/core')

local NameColumn = {}

function NameColumn.new()
  local Column = require('vfiler/columns/column')
  local self = core.inherit(NameColumn, Column)
  self.variable = true
  self.stretch = true

  self.min_width = 8
  self.max_width = 0

  local Syntax = require('vfiler/columns/syntax')
  self._syntax = Syntax.new({
    syntaxes = {
      selected = {
        group = 'vfilerName_Selected',
        start_mark = 'n@s\\',
        highlight = 'vfilerSelected',
      },
      file = {
        group = 'vfilerName_File',
        start_mark = 'n@f\\',
        highlight = 'vfilerFile',
      },
      directory = {
        group = 'vfilerName_Directory',
        start_mark = 'n@d\\',
        highlight = 'vfilerDirectory',
      },
      link = {
        group = 'vfilerName_Link',
        start_mark = 'n@l\\',
        highlight = 'vfilerLink',
      },
      hidden = {
        group = 'vfilerName_Hidden',
        start_mark = 'n@h\\',
        highlight = 'vfilerHidden',
      },
    },
    end_mark = '\\n@',
  })
  return self
end

function NameColumn:get_text(item, width)
  local name = item.name
  local syntax_name
  if item.selected then
    syntax_name = 'selected'
  elseif item.name:sub(1, 1) == '.' then
    syntax_name = 'hidden'
  elseif item.islink then
    syntax_name = 'link'
  elseif item.isdirectory then
    syntax_name = 'directory'
  else
    syntax_name = 'file'
  end

  -- append directory mark
  if item.isdirectory then
    name = name .. '/'
  end

  return self._syntax:surround_text(
    syntax_name,
    core.string.truncate(name, width, '..', math.floor(width / 2))
  )
end

function NameColumn:get_width(items, width)
  if self.max_width <= 0 then
    return math.max(width, self.min_width)
  end
  return core.math.within(width, self.min_width, self.max_width)
end

return NameColumn
