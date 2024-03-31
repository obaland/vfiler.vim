local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local event = require('vfiler/events/event')
local vim = require('vfiler/libs/vim')

local extensions = {}

local Extension = {}
Extension.__index = Extension

local function get_win_size(winid)
  local screen_pos = vim.fn.win_screenpos(winid)
  return {
    width = vim.fn.winwidth(winid),
    height = vim.fn.winheight(winid),
    row = screen_pos[1],
    col = screen_pos[2],
  }
end

local function winvalue(value, win_value, content_value, min, max)
  local result
  if value == 'auto' then
    result = content_value
  else
    local v = tonumber(value)
    if not v then
      core.message.error('Illegal config value: ' .. value)
      return
    end

    if core.math.type(v) == 'float' then
      v = math.floor(win_value * v)
    end
    result = v
  end
  return math.floor(core.math.within(result, min, max))
end

local function to_window_options(options, name, win_size, content_size)
  local layout
  local woptions = {
    title = name,
  }
  if options.floating then
    layout = 'floating'
    local floating = options.floating
    local minwidth = floating.minwidth or 1
    local minheight = floating.minheight or 1
    local maxwidth = floating.maxwidth or content_size.width
    local maxheight = floating.maxheight or content_size.height

    woptions.width = winvalue(
      floating.width,
      win_size.width,
      content_size.width,
      minwidth,
      maxwidth
    )
    woptions.height = winvalue(
      floating.height,
      win_size.height,
      content_size.height,
      minheight,
      maxheight
    )
  elseif options.top or options.bottom then
    layout = options.top and 'top' or 'bottom'
    local value = options.top or options.bottom
    woptions.width = 0

    -- in the window, if 'auto', add one spece line.
    local content_height = content_size.height
    if value == 'auto' then
      content_height = content_height + 1
    end
    woptions.height =
      winvalue(value, win_size.height, content_height, 1, win_size.height)
  elseif options.right or options.left then
    layout = options.right and 'right' or 'left'
    local value = options.right or options.left
    woptions.width =
      winvalue(value, win_size.width, content_size.width, 1, win_size.width)
    woptions.height = 0
  end

  -- width correction including the title string.
  if woptions.width ~= 0 then
    -- '2' is space width
    woptions.width = math.max(vim.fn.strwidth(name) + 2, woptions.width)
  end

  -- set window position
  if options.floating then
    if options.floating.relative then
      local offset_row = math.floor((win_size.height - woptions.height) / 2)
      local offset_col = math.floor((win_size.width - woptions.width) / 2)
      woptions.col = win_size.col + offset_col - 1
      woptions.row = win_size.row + offset_row - 1
    else
      local columns = vim.get_option('columns')
      local lines = vim.get_option('lines')
      local offset_row = math.floor((lines - woptions.height) / 2)
      local offset_col = math.floor((columns - woptions.width) / 2)
      woptions.col = offset_col - 1
      woptions.row = offset_row - 1
    end
  end
  return woptions, layout
end

local function new_window(options)
  local window
  if core.is_nvim and options.floating then
    window = require('vfiler/windows/floating')
  else
    window = require('vfiler/windows/window')
  end
  return window.new()
end

function Extension.new(filer, name, configs, options)
  local buffer = require('vfiler/buffer').new(name)
  -- set default buffer options
  buffer:set_options({
    bufhidden = 'wipe',
    buflisted = false,
    buftype = 'nofile',
    modifiable = false,
    modified = false,
    readonly = true,
  })

  local self = setmetatable({
    name = name,
    _buffer = buffer,
    _src_bufnr = vim.fn.bufnr(),
    _src_winid = vim.fn.win_getid(),
    _configs = core.table.copy(configs),
    _filer = filer,
    _items = nil,
    _window = nil,
    _mappings = nil,
    _event = nil,
  }, Extension)
  -- set options

  for key, value in pairs(options) do
    self[key] = value
  end
  return self
end

-- @param bufnr number
function Extension.get(bufnr)
  return extensions[bufnr]
end

-- @param bufnr number
function Extension.delete(bufnr)
  local ext = extensions[bufnr]
  if ext then
    ext:quit()
  end
  extensions[bufnr] = nil
end

function Extension._do_action(bufnr, key)
  local ext = Extension.get(bufnr)
  if not ext then
    core.message.error('Extension does not exist.')
    return
  end
  local action = ext._mappings[key]
  if not action then
    core.message.error('Not defined in the key')
    return
  end
  ext:do_action(action)
end

--- Do action
---@param action function
function Extension:do_action(action)
  action(self)
end

--- Get the item in the specified line number
---@param lnum number?
function Extension:get_item(lnum)
  lnum = lnum or vim.fn.line('.')
  return self._items[lnum]
end

--- Find the index of the item in the view buffer for the item
---@param item any
function Extension:indexof(item)
  for i = 1, #self._items do
    if item == self._items[i] then
      return i
    end
  end
  return 0
end

--- Get the number of line in the view buffer
function Extension:num_lines()
  return #self._items
end

function Extension:quit()
  local bufnr = self._buffer.number
  -- guard duplicate calls
  if not extensions[bufnr] then
    return
  end
  extensions[bufnr] = nil

  cmdline.clear_prompt()
  self._window:close()
  if self.on_quit then
    self._filer:do_action(self.on_quit)
  end
  core.window.move(self._src_winid)

  -- unlink
  self._filer._context.extension = nil
end

function Extension:redraw()
  self._items = self:_on_update(self._configs)
  local lines = self:_get_lines(self._items)
  self:_on_draw(self._buffer, lines)
end

function Extension:start()
  local configs = self._configs
  self._items = self:_on_initialize(configs)
  if not self._items then
    return
  end
  local lines, width = self:_get_lines(self._items)

  -- to view options
  local window = new_window(configs.options)
  local win_size = get_win_size(self._src_winid)
  local content_size = {
    width = width,
    height = #lines,
  }
  local woptions, layout =
    to_window_options(configs.options, self.name, win_size, content_size)
  if layout ~= 'floating' then
    core.window.open(layout)
  end
  local winid = window:open(self._buffer, woptions)
  window:set_options(self:_get_win_options(configs))
  window:set_title(self.name)
  local lnum = self:_on_opened(winid, self._buffer, self._items, configs)
  self._window = window

  -- define key mappings (overwrite)
  local define = function(mappings)
    local funcstr = [[require('vfiler/extensions/extension')._do_action]]
    if window:type() == 'popup' then
      return window:define_mappings(mappings, funcstr)
    end
    return self._buffer:define_mappings(mappings, funcstr)
  end
  self._mappings = define(configs.mappings)

  -- register events
  for group, elist in pairs(configs.events) do
    local events = {}
    for _, e in ipairs(elist) do
      table.insert(events, {
        event = e.event,
        callback = function(_, _, _)
          self:do_action(e.action)
        end,
      })
    end
    event.register(group, events, self._buffer.number)
  end

  -- draw line texts and syntax
  self:_on_draw(self._buffer, lines)
  core.cursor.winmove(winid, lnum)

  -- add extension table
  extensions[self._buffer.number] = self

  -- link to filer
  self._filer._context.extension = self
end

function Extension:reload()
  local configs = self._configs
  self._items = self:_on_update(configs)
  if not self._items then
    return
  end
  local lines, width = self:_get_lines(self._items)

  -- to view options
  local win_size = get_win_size(self._window.src_winid)
  local content_size = {
    width = width,
    height = #lines,
  }
  local woptions =
    to_window_options(configs.options, self.name, win_size, content_size)
  self._window:open(self._buffer, woptions)
  self._window:set_options(self:_get_win_options(configs))
  self._window:set_title(self.name)
  self:_on_draw(self._buffer, lines)
  vim.command('normal zb')
end

function Extension:winid()
  if not self._window then
    return 0
  end
  return self._window:id()
end

function Extension:_close()
  local bufnr = self._buffer.number
  -- guard duplicate calls
  if not (self._window and extensions[bufnr]) then
    return false
  end
  extensions[bufnr] = nil

  cmdline.clear_prompt()
  self._window:close()
  return true
end

function Extension:_on_initialize(configs)
  -- Not implemented
  return {} -- return items
end

function Extension:_on_update(configs)
  -- Not implemented
  return {} -- return items
end

function Extension:_on_draw(buffer, lines)
  local modifiable = buffer:get_option('modifiable') == 1
  if not modifiable then
    buffer:set_option('modifiable', true)
    buffer:set_option('readonly', false)
  end
  buffer:set_lines(lines)
  if not modifiable then
    buffer:set_option('modifiable', false)
    buffer:set_option('readonly', true)
    buffer:set_option('modified', false)
  end
end

function Extension:_on_opened(winid, buffer, items, configs)
  -- Not implemented
  return 1 -- return initial cursor lnum
end

function Extension:_get_lines(items, winwidth)
  return nil
end

function Extension:_get_win_options(configs)
  local options = {
    number = false,
  }
  -- NOTE: For vim, don't explicitly set the "signcolumn" option as the
  -- screen may flicker.
  if core.is_nvim then
    options.signcolumn = 'no'
  end
  return options
end

return Extension
