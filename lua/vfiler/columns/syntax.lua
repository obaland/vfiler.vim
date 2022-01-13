local core = require('vfiler/core')
local vim = require('vfiler/vim')

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
    if syntax.pattern then
      command = core.syntax.match_command(
        syntax.group,
        syntax.pattern,
        options
      )
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
  return self._syntaxes[name].start_mark .. str .. self._end_mark,
    vim.fn.strwidth(str)
end

return Syntax
