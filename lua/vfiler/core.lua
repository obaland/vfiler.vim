local vim = require 'vfiler/vim'

local M = {}

M.is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

function M.concat_list(dest, src)
  local pos = #dest
  for i = 1, #src do
    table.insert(dest, pos + i, src[i])
  end
  return dest
end

function M.deepcopy(src)
  local copied
  if type(src) == 'table' then
    copied = {}
    for key, value in next, src, nil do
      copied[M.deepcopy(key)] = M.deepcopy(value)
    end
    setmetatable(copied, M.deepcopy(getmetatable(src)))
  else -- number, string, boolean, etc
    copied = src
  end
  return copied
end

function M.inherit(class, super, ...)
  local self = (super and super.new(...) or {})
  setmetatable(self, {__index = class})
  setmetatable(class, {__index = super})
  return self
end

function M.normalized_path(path)
  if path == '/' then
    return '/'
  end
  -- trim trailing path separator
  local result = vim.fn.fnamemodify(vim.fn.resolve(path), ':p')
  local len = result:len()

  if result:match('/$') or result:match('\\$') then
    result = result:sub(0, len - 1)
  end

  if M.is_windows then
    result = result:gsub('\\', '/')
  end

  return result
end

-- Lua pettern escape
if vim.fn.has('nvim') then
  M.pesc = vim.pesc
else
  function M.pesc(s)
    return s
  end
end

-- print error message
function M.error(message)
  vim.command(
    string.format('echohl ErrorMsg | echo "%s" | echohl None', message)
  )
end

-- print warning message
function M.warning(message)
  vim.command(
    string.format('echohl WarningMsg | echo "%s" | echohl None', message)
  )
end

-- Escape because of the vim pattern
function M.vim_pattern_escape(str)
  return str:gsub('(\\)', '\\%1')
end

-- syntax match command
function M.syntax_match_command(name, pattern, ...)
   local command = string.format('syntax match %s /%s/', name, pattern)
   if ... then
     local options = {}
     for key, value in pairs(...) do
       local option = ''
       if type(value) ~= "boolean" then
         option = string.format('%s=%s', key, value)
       else
         option = key
       end
       table.insert(options, option)
     end
     command = command .. ' ' .. table.concat(options, ' ')
   end
   return command
end

-- highlight command
function M.link_highlight_command(from, to)
  return string.format('highlight! default link %s %s', from, to)
end

return M
