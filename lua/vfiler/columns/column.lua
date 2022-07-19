local core = require('vfiler/libs/core')

local function create_syntax_commands(syntaxes, end_mark)
  -- sort the definition order
  local syntax_list = {}
  for _, syntax in pairs(syntaxes) do
    table.insert(syntax_list, syntax)
  end
  table.sort(syntax_list, function(a, b)
    local p1 = a.priority or 0
    local p2 = b.priority or 0
    return p1 < p2
  end)

  local group_names = {}
  local commands = {}

  end_mark = core.string.vesc(end_mark)
  for _, syntax in ipairs(syntax_list) do
    -- set options
    local options = {}
    if syntax.options then
      core.table.merge(options, syntax.options)
    end

    local command
    if syntax.keyword then
      command =
        core.syntax.keyword_command(syntax.group, syntax.keyword, options)
    elseif syntax.pattern then
      command =
        core.syntax.match_command(syntax.group, syntax.pattern, options)
    else
      local start_mark = core.string.vesc(syntax.start_mark)
      options.concealends = true
      command = core.syntax.region_command(
        syntax.group,
        start_mark,
        end_mark,
        syntax.group .. 'Mark',
        options
      )
    end

    table.insert(commands, command)
    table.insert(group_names, syntax.group)
  end

  -- clear syntax (insert at the first of command list)
  table.insert(commands, 1, core.syntax.clear_command(group_names))
  return commands
end

local function create_highlight_commands(syntaxes)
  local commands = {}
  for _, syntax in pairs(syntaxes) do
    local hl = syntax.highlight
    if hl then
      if type(hl) == 'string' then
        table.insert(commands, core.highlight.link_command(syntax.group, hl))
      elseif type(hl) == 'table' then
        table.insert(commands, core.highlight.command(syntax.group, hl))
      else
        core.message.error('Illegal "highlight" type. (%s)', type(hl))
      end
    end
  end
  return commands
end

---@class Syntax
local Syntax = {}
Syntax.__index = Syntax

function Syntax.new(configs)
  local syntaxes = configs.syntaxes
  return setmetatable({
    _syntaxes = configs.syntaxes,
    _end_mark = configs.end_mark,
    _syntax_commands = create_syntax_commands(syntaxes, configs.end_mark),
    _highlight_commands = create_highlight_commands(syntaxes),
  }, Syntax)
end

function Syntax:syntaxes()
  return self._syntax_commands
end

function Syntax:highlights()
  return self._highlight_commands
end

function Syntax:surround_text(name, str)
  return self._syntaxes[name].start_mark .. str .. self._end_mark
end

---@class Column
local Column = {}
Column.__index = Column

function Column.new(syntaxes)
  local syntax = nil
  if syntaxes then
    syntax = Syntax.new(syntaxes)
  end
  return setmetatable({
    variable = false,
    stretch = false,
    _syntax = syntax,
  }, Column)
end

function Column:get_text(item, width)
  local text = self:_get_text(item, width)
  local text_width = vim.fn.strwidth(text)
  if self._syntax then
    local syntax = self:_get_syntax_name(item, width)
    return self._syntax:surround_text(syntax, text), text_width
  end
  return text, text_width
end

function Column:get_width(items, width)
  return 0
end

function Column:highlights()
  if self._syntax then
    return self._syntax:highlights()
  end
  return nil
end

function Column:syntaxes()
  if self._syntax then
    return self._syntax:syntaxes()
  end
  return nil
end

function Column:_get_text(item, width)
  return ''
end

function Column:_get_syntax_name(item, width)
  return ''
end

return Column
