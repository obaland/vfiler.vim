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

function M.merge_table(dest, src)
  for key, value in pairs(src) do
    if type(value) == 'table' then
      if not dest[key] then
        dest[key] = {}
      end
      M.merge_table(dest[key], value)
    else
      dest[key] = value
    end
  end
  return dest
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
  vim.command(('echohl ErrorMsg | echo "%s" | echohl None'):format(message))
end

-- print warning message
function M.warning(message)
  vim.command(('echohl WarningMsg | echo "%s" | echohl None'):format(message))
end

-- Escape because of the vim pattern
function M.vesc(s)
  return s:gsub('([\\^*$.~])', '\\%1')
end

-- syntax command
function M.syntax_clear_command(names)
  return ('silent! syntax clear %s'):format(table.concat(names, ' '))
end

function M.syntax_match_command(name, pattern, ...)
   local command = ('syntax match %s /%s/'):format(name, pattern)
   if ... then
     local options = {}
     for key, value in pairs(...) do
       local option = ''
       if type(value) ~= 'boolean' then
         option = ('%s=%s'):format(key, value)
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
  return ('highlight! default link %s %s'):format(from, to)
end

-- resize window
function M.resize_window_height(height)
  vim.command('silent! resize ' .. height)
end

function M.resize_window_width(width)
  vim.command('silent! vertical resize ' .. width)
end

-- truncate string
local function strwidthpart(str, width)
  local vcol = width + 2
  return vim.fn.matchstr(str, [[.*\%<]] .. vcol .. 'v')
end

local function strwidthpart_reverse(str, strwidth, width)
  local vcol = strwidth - width
  return vim.fn.matchstr(str, [[\%>]] .. vcol .. 'v.*')
end

local function truncate(str, width)
  local bytes = {str:byte(1, #str)}
  for _, byte in ipairs(bytes) do
    if (0 > byte) or (byte > 127) then
      return strwidthpart(str, width)
    end
  end
  return str:sub(1, width)
end

function M.truncate(str, width, sep, ...)
  local strwidth = vim.fn.strwidth(str)
  if strwidth <= width then
    return str
  end
  local footer_width = ... or 0
  local header_width = width - vim.fn.strwidth(sep) - footer_width
  local replaced = str:gsub('\t', '')
  local result = strwidthpart(replaced, header_width) ..  sep ..
                 strwidthpart_reverse(replaced, strwidth, footer_width)
  return truncate(result, width)
end

return M
