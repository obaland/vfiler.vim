local core = require('vfiler/libs/core')

local NameColumn = {}

function NameColumn.new()
  local end_mark = '/>n'

  local Column = require('vfiler/columns/column')
  local self = core.inherit(NameColumn, Column, {
    {
      group = 'vfilerName_Selected',
      name = 'selected',
      region = {
        start_mark = 'n.*</',
        end_mark = end_mark,
      },
      highlight = 'vfilerSelected',
    },
    {
      group = 'vfilerName_File',
      name = 'file',
      region = {
        start_mark = 'n..</',
        end_mark = end_mark,
      },
      highlight = 'vfilerFile',
    },
    {
      group = 'vfilerName_Directory',
      name = 'directory',
      region = {
        start_mark = 'n.,</',
        end_mark = end_mark,
      },
      highlight = 'vfilerDirectory',
    },
    {
      group = 'vfilerName_Link',
      name = 'link',
      region = {
        start_mark = 'n._</',
        end_mark = end_mark,
      },
      highlight = 'vfilerLink',
    },
    {
      group = 'vfilerName_Hidden',
      name = 'hidden',
      region = {
        start_mark = 'n.~</',
        end_mark = end_mark,
      },
      highlight = 'vfilerHidden',
    },
    {
      group = 'vfilerName_Socket',
      name = 'socket',
      region = {
        start_mark = 'n.=</',
        end_mark = end_mark,
      },
      highlight = 'vfilerSocket',
    },
    {
      group = 'vfilerName_Fifo',
      name = 'fifo',
      region = {
        start_mark = 'n.|</',
        end_mark = end_mark,
      },
      highlight = 'vfilerFifo',
    },
  })
  self.variable = true
  self.stretch = true

  self.min_width = 8
  self.max_width = 0
  return self
end

function NameColumn:to_text(item, width)
  local syntax
  if item.selected then
    syntax = 'selected'
  elseif item.name:sub(1, 1) == '.' then
    syntax = 'hidden'
  elseif item.link then
    syntax = 'link'
  else
    syntax = item.type
  end

  local name = item.name
  -- append directory mark
  if item.type == 'directory' then
    name = name .. '/'
  end
  local text = core.string.truncate(name, width, '..', math.floor(width / 2))
  return {
    string = text,
    width = vim.fn.strwidth(text),
    syntax = syntax,
  }
end

function NameColumn:get_width(items, width, winid)
  if self.max_width <= 0 then
    return math.max(width, self.min_width)
  end
  return core.math.within(width, self.min_width, self.max_width)
end

return NameColumn
