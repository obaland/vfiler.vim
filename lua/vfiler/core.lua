local vim = require 'vfiler/vim'

local M = {}

------------------------------------------------------------------------------
-- Core
------------------------------------------------------------------------------
M.is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

function M.inherit(class, super, ...)
  local self = (super and super.new(...) or {})
  setmetatable(self, {__index = class})
  setmetatable(class, {__index = super})
  return self
end

------------------------------------------------------------------------------
-- File
------------------------------------------------------------------------------
if M.is_windows then
  function M.copy_directory(src, dest)
    --return vim.fn.system(('copy /y %s %s'):format(src, dest))
  end

  function M.copy_file(src, dest)
    vim.fn.system(('copy /y %s %s'):format(src, dest))
  end
else
  function M.copy_directory(src, dest)
    os.execute(('cp -R %s %s'):format(src, dest))
  end

  function M.copy_file(src, dest)
    os.execute(('cp %s %s'):format(src, dest))
  end
end

------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------
M.window = {}

local open_directions = {
  bottom = 'belowright split',
  left = 'aboveleft vertical split',
  right = 'belowright vertical split',
  tab = 'tabnew',
  top = 'aboveleft split',
}

---@param winnr number
function M.window.move(winnr)
  local command = 'wincmd w'
  if winnr > 0 then
    command = winnr .. command
  end
  vim.command(([[noautocmd execute '%s']]).format(command))
end

---@param direction string
---@vararg string
function M.window.open(direction, ...)
  local command = 'silent! ' .. open_directions[direction]
  if ... then
    command = ('%s %s'):format(command, ...)
  end
  vim.command(command)
end

---@param height number
function M.window.resize_height(height)
  vim.command('silent! resize ' .. height)
end

---@param width number
function M.window.resize_width(width)
  vim.command('silent! vertical resize ' .. width)
end

------------------------------------------------------------------------------
-- Message
------------------------------------------------------------------------------
M.message = {}

---print error message
function M.message.error(format, ...)
  vim.fn['vfiler#core#error'](format:format(...))
end

---print information message
function M.message.info(format, ...)
  vim.fn['vfiler#core#info'](format:format(...))
end

---print warning message
function M.message.warning(format, ...)
  vim.fn['vfiler#core#warning'](format:format(...))
end

------------------------------------------------------------------------------
-- Path utilities
------------------------------------------------------------------------------
M.path = {}

function M.path.exists(path)
  return vim.fn.filereadable(path) == 1
end

function M.path.isdirectory(path)
  return vim.fn.isdirectory(path) == 1
end

function M.path.join(path, name)
  if path:sub(#path, #path) ~= '/' then
    path = path .. '/'
  end
  if name:sub(1, 1) == '/' then
    name = name:sub(2)
  end
  return path .. name
end

function M.path.normalize(path)
  if path == '/' then
    return '/'
  end

  local result = vim.fn.fnamemodify(path, ':p')
  if M.is_windows then
    result = result:gsub('\\', '/')
  end
  return result
end

function M.path.root(path)
  local root = ''
  if M.is_windows then
    if path:match('^//') then
      -- for UNC path
      root = path:match('^//[^/]*/[^/]*')
    else
      root = (M.path.normalize(path)):match('^%a+:')
    end
  end
  return root .. '/'
end

------------------------------------------------------------------------------
-- syntax and highlight command utilities
------------------------------------------------------------------------------
M.syntax = {}
M.highlight = {}

function M.syntax.clear_command(names)
  return ('silent! syntax clear %s'):format(table.concat(names, ' '))
end

function M.syntax.match_command(name, pattern, ...)
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
function M.highlight.link_command(from, to)
  return ('highlight! default link %s %s'):format(from, to)
end

------------------------------------------------------------------------------
-- String utilities
------------------------------------------------------------------------------
M.string = {}

-- Lua pettern escape
if vim.fn.has('nvim') then
  M.string.pesc = vim.pesc
else
  function M.string.pesc(s)
    return s
  end
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

if M.is_windows then
  function M.string.shellescape(str)
    return ('"%s"'):format(vim.fn.escape(str:gsub('/', [[\]])))
  end
else
  function M.string.shellescape(str)
    return vim.fn.shellescape(str)
  end
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

function M.string.truncate(str, width, sep, ...)
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

-- Escape because of the vim pattern
function M.string.vesc(s)
  return s:gsub('([\\^*$.~])', '\\%1')
end

------------------------------------------------------------------------------
-- Table and List
------------------------------------------------------------------------------
M.list = {}
M.table = {}

function M.list.extend(dest, src)
  local pos = #dest
  for i = 1, #src do
    table.insert(dest, pos + i, src[i])
  end
  return dest
end

function M.table.copy(src)
  local copied
  if type(src) == 'table' then
    copied = {}
    for key, value in next, src, nil do
      copied[M.table.copy(key)] = M.table.copy(value)
    end
    setmetatable(copied, M.table.copy(getmetatable(src)))
  else -- number, string, boolean, etc
    copied = src
  end
  return copied
end

function M.table.merge(dest, src)
  for key, value in pairs(src) do
    if type(value) == 'table' then
      if not dest[key] then
        dest[key] = {}
      end
      M.table.merge(dest[key], value)
    else
      dest[key] = value
    end
  end
  return dest
end

------------------------------------------------------------------------------
-- Math utilities
------------------------------------------------------------------------------
M.math = {}

-- Within the max and min between
function M.math.within(v, min, max)
  return math.min(math.max(v, min), max)
end

return M
