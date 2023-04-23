local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Column = {}
Column.__index = Column

local function create_syntax(syntax)
  -- Set default options
  local syn_options = syntax.options or {}
  syn_options.display = true
  syn_options.oneline = true

  local command = ''
  -- syntax
  if syntax.region then
    -- Add options
    syn_options.concealends = true

    local region = syntax.region
    command = core.syntax.create(syntax.group, {
      region = {
        start_pattern = core.string.vesc(region.start_mark),
        end_pattern = core.string.vesc(region.end_mark),
        matchgroup = syntax.group .. 'Conceal',
      },
    }, syn_options)
  elseif syntax.match then
    command = core.syntax.create(syntax.group, {
      match = syntax.match,
    }, syn_options)
  elseif syntax.keyword then
    local keyword = string.gsub(syntax.keyword, '%s', '')
    if #keyword > 0 then
      command = core.syntax.create(syntax.group, {
        keyword = syntax.keyword,
      }, syn_options)
    end
  else
    core.message.error('Nothing the "syntax type". (%s)', syntax.name)
  end
  return command
end

local function create_highlight(syntax)
  local hi = syntax.highlight
  if not hi then
    return ''
  end

  local command
  if type(hi) == 'string' then
    command = core.highlight.link(syntax.group, hi)
  elseif type(hi) == 'table' then
    command = core.highlight.create(syntax.group, hi)
  else
    core.message.error('Illegal "highlight" type. (%s)', type(hi))
  end
  return command
end

function Column.new(syntaxes)
  local self = setmetatable({
    variable = false,
    stretch = false,
    _marks = {},
    _hi_commands = {},
    _syn_commands = {},
  }, Column)
  if syntaxes then
    self:_initialize(syntaxes)
  end
  return self
end

function Column:get_text(item, width)
  return '', 0
end

function Column:get_width(items, width)
  return 0
end

function Column:highlights()
  return self._hi_commands
end

function Column:surround_text(name, text)
  local mark = self._marks[name]
  if (not mark) or vim.get_win_option(0, 'conceallevel') < 2 then
    return text
  end
  return mark.start_mark .. text .. mark.end_mark
end

function Column:syntaxes()
  return self._syn_commands
end

function Column:_initialize(syntaxes)
  for _, syntax in ipairs(syntaxes) do
    local command = create_syntax(syntax)
    if #command > 0 then
      table.insert(self._syn_commands, command)
    end

    -- Add marks
    if syntax.region then
      local region = syntax.region
      self._marks[syntax.name] = {
        start_mark = region.start_mark,
        end_mark = region.end_mark,
      }
    end

    -- highlight
    command = create_highlight(syntax)
    if #command > 0 then
      table.insert(self._syn_commands, command)
    end
  end
end

return Column
