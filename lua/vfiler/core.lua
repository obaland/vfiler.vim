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

function M.get_root_path(path)
  local root = '/'
  if M.is_windows and path:match('^//') then
    root = path:match('^//[^/]*/[^/]*')
  elseif M.is_windows then
    root = (M.normalized_path(path) .. '/'):match('^%a+:/')
  end
  return root
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

------------------------------------------------------------------------------
-- Input utility
------------------------------------------------------------------------------

function M.input(prompt, ...)
  local args = ... or {}
  local text = args[1] or ''
  local completion = args[2]

  prompt = ('[vfiler] %s: '):format(prompt)

  local content = ''
  if completion then
    content = vim.fn.input(prompt, text, completion)
  else
    content = vim.fn.input(prompt, text)
  end
  -- TODO:
  vim.command('echon')
  return content
end

------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------

local open_window_types = {
  bottom = 'belowright split',
  left = 'aboveleft vertical split',
  right = 'belowright vertical split',
  tab = 'tabnew',
  top = 'aboveleft split',
}

---@param winnr number
function M.move_window(winnr)
  local command = 'wincmd w'
  if winnr > 0 then
    command = winnr .. command
  end
  vim.command(([[noautocmd execute '%s']]).format(command))
end

---@param type string
---@vararg string
function M.open_window(type, ...)
  local command = 'silent! ' .. open_window_types[type]
  if ... then
    command = ('%s %s'):format(command, ...)
  end
  vim.command(command)
end

---@param height number
function M.resize_window_height(height)
  vim.command('silent! resize ' .. height)
end

---@param width number
function M.resize_window_width(width)
  vim.command('silent! vertical resize ' .. width)
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

------------------------------------------------------------------------------
-- Message
------------------------------------------------------------------------------

---print error message
---@param message string
function M.error(message)
  vim.fn['vfiler#core#error'](message)
end

---print information message
---@param message string
function M.info(message)
  vim.fn['vfiler#core#info'](message)
end

---print warning message
---@param message string
function M.warning(message)
  vim.fn['vfiler#core#warning'](message)
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

---Generate highlight command string
---@param from string
---@param to string
---@return string
function M.link_highlight_command(from, to)
  return ('highlight! default link %s %s'):format(from, to)
end

-- truncate string
local function strwidthpart(str, width)
  local vcol = width + 2
  return vim.fn.matchstr(str, '.*\\%<' .. vcol .. 'v')
end

local function strwidthpart_reverse(str, strwidth, width)
  local vcol = strwidth - width
  return vim.fn.matchstr(str, '\\%>' .. vcol .. 'v.*')
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

-- Within the max and min between
function M.within(v, min, max)
  return math.min(math.max(v, min), max)
end

return M
