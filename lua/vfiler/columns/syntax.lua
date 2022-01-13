local core = require('vfiler/core')
local vim = require('vfiler/vim')

local Syntax = {}
Syntax.__index = Syntax

function Syntax.new(configs)
  return setmetatable({
    _syntaxes = configs.syntaxes,
    _end_mark = configs.end_mark,
    _ignore_group = configs.ignore_group,
  }, Syntax)
end

function Syntax:syntaxes()
  local end_mark = core.string.vesc(self._end_mark)
  local group_names = {}
  local commands = {}

  for _, syntax in pairs(self._syntaxes) do
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

function Syntax:highlights()
  local commands = {}
  for _, syntax in pairs(self._syntaxes) do
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

function Syntax:surround_text(name, str)
  return self._syntaxes[name].start_mark .. str .. self._end_mark,
    vim.fn.strwidth(str)
end

return Syntax
