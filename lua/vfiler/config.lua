local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}
M.configs = {}

local default_options = {
  auto_cd = false,
  columns = 'indent,icon,name,mode,size,time',
  listed = true,
  name = '',
  show_hidden_files = false,
  sort = 'name',
}

M.configs.options = core.table.copy(default_options)

local function error(message)
  core.message.error('Argument error - %s', message)
end

local function normalize(value)
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
    value = normalize(value)
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

function M.parse_options(str_args)
  local args = split(str_args)
  local options = core.table.copy(M.configs.options)
  local path = ''

  for _, arg in ipairs(args) do
    if arg:sub(1, 1) == '-' then
      local name, value, key = parse_option(arg)
      if options[name] == nil then
        error(string.format("Unknown '%s' option.", key))
        return nil
      elseif type(value) ~= type(options[name]) then
        error(string.format("Illegal option value. (%s)", value))
        return nil
      end
      options[name] = value
    else
      if #path > 0 then
        error('The path specification is duplicated.')
        return nil
      end
      path = normalize(arg)
    end
  end
  return options, path
end

function M.setup(configs)
  core.table.merge(M.configs, configs)
end

return M
