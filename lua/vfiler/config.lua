local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

local defalut_configs = {
  auto_cd = false,
  listed = false,
  name = '',
}

local function error(message)
  core.error('Argument error - ' .. message)
end

local function normalized_value(value)
  if type(value) ~= 'string' then
    return value
  end
  if not core.is_windows then
    value = value:gsub('\\', '/')
  end
  return vim.fn.trim(value, ' "')
end

local function split(str_args)
  local args = {}
  local pos = 1
  local escaped, in_dquote = false, false

  for i = 1, #str_args do
    local char = str_args:sub(i, i)
    if char == ' ' and not (escaped or in_dquote) then
      table.insert(args, str_args:sub(pos, i - 1))
      pos = i + 1 -- reset position
    elseif char == '"' then
      in_dquote = not in_dquote
    end
    escaped = char == '\\'
  end
  -- insert the rest of string
  table.insert(args, str_args:sub(pos))
  return args
end

local function parse_option(arg)
  local key, value = arg:match('^%-([%-%w]+)=(.+)')
  if key then
    value = normalized_value(value)
  else
    key = arg:match('^%-no%-(%g+)')
    if key then
      value = false
    else
      key = arg:sub(2) -- remove '-'
      value = true
    end
  end
  -- replace for option property name
  return key:gsub('%-', '_'), value, key
end

function M.parse(str_args)
  local args = split(str_args)

  -- copy from default
  local configs = core.deepcopy(defalut_configs)
  configs.path = ''

  for _, arg in ipairs(args) do
    if arg:sub(1, 1) == '-' then
      local name, value, key = parse_option(arg)
      if configs[name] == nil then
        error(string.format("Unknown '%s' option.", key))
        return nil
      elseif type(value) ~= type(configs[name]) then
        error(string.format("Illegal option value. (%s)", value))
        return nil
      end
      configs[name] = value
    else
      if #configs.path > 0 then
        error('The path specification is duplicated.')
        return nil
      end
      configs.path = normalized_value(arg)
    end
  end
  return configs
end

return M
