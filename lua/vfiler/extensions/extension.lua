local cmdline = require('vfiler/libs/cmdline')
local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local extensions = {}

local Extension = {}
Extension.__index = Extension

local function new_buffer(name)
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
  return buffer
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

    if tostring(value):match('%d+%.%d+') then
      -- float
      v = math.floor(win_value * v)
    end
    result = v
  end
  return math.floor(core.math.within(result, min, max))
end

local function to_view_options(options, name, win_size, content_size)
  local voptions = {
    title = name,
  }
  if options.floating then
    voptions.layout = 'floating'

    local floating = options.floating
    local minwidth = floating.minwidth or 1
    local minheight = floating.minheight or 1

    voptions.width = winvalue(
      floating.width,
      win_size.width,
      content_size.width,
      minwidth,
      win_size.width
    )
    voptions.height = winvalue(
      floating.height,
      win_size.height,
      content_size.height,
      minheight,
      win_size.height
    )
  elseif options.top or options.bottom then
    voptions.layout = options.top and 'top' or 'bottom'
    local value = options.top or options.bottom
    voptions.width = 0
    voptions.height = winvalue(
      value,
      win_size.height,
      content_size.height,
      1,
      win_size.height
    )
  elseif options.right or options.left then
    voptions.layout = options.right and 'right' or 'left'
    local value = options.right or options.left
    voptions.width = winvalue(
      value,
      win_size.width,
      content_size.width,
      1,
      win_size.width
    )
    voptions.height = 0
  end

  -- '2' is space width
  voptions.width = math.max(vim.fn.strwidth(name) + 2, voptions.width)

  -- set window position
  if options.floating then
    if options.floating.relative then
      local offset_row = math.floor((win_size.height - voptions.height) / 2)
      local offset_col = math.floor((win_size.width - voptions.width) / 2)
      voptions.col = win_size.col + offset_col - 1
      voptions.row = win_size.row + offset_row - 1
    else
      local columns = vim.get_option('columns')
      local lines = vim.get_option('lines')
      local offset_row = math.floor((lines - voptions.height) / 2)
      local offset_col = math.floor((columns - voptions.width) / 2)
      voptions.col = offset_col - 1
      voptions.row = offset_row - 1
    end
  end
  return voptions
end

local function new_view(options)
  local view
  if options.floating then
    if core.is_nvim then
      view = require('vfiler/views/floating')
    else
      view = require('vfiler/views/popup')
    end
  else
    view = require('vfiler/views/window')
  end
  return view.new()
end

function Extension.new(filer, name, configs, options)
  local self = setmetatable({
    name = name,
    _buffer = nil,
    _src_bufnr = vim.fn.bufnr(),
    _configs = core.table.copy(configs),
    _filer = filer,
    _items = nil,
    _view = nil,
    _mappings = nil,
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

function Extension._handle_event(bufnr, group, type)
  local ext = Extension.get(bufnr)
  if not ext then
    return
  end
  local events = ext._configs.events[group]
  if not events then
    core.message.error('Event group "%s" is not registered.', group)
    return
  end
  local action = events[type]
  if not action then
    core.message.error('Event "%s" is not registered.', type)
    return
  end
  ext:do_action(action)
end

--- Do action
---@param action function
function Extension:do_action(action)
  action(self)
end

--- Get the item on the current cursor
function Extension:get_current()
  return self:get_item(vim.fn.line('.'))
end

--- Get the item in the specified line number
---@param lnum number
function Extension:get_item(lnum)
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
  self._view:close()
  if self.on_quit then
    self._filer:do_action(self.on_quit)
  end
  core.window.move(self._view.src_winid)

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

  -- create buffer
  self._buffer = new_buffer(self.name)
  self._buffer:set_options(self:_get_buf_options(configs))

  -- to view options
  self._view = new_view(configs.options)
  local src_winid = self._view.src_winid
  local screen_pos = vim.fn.win_screenpos(src_winid)
  local win_size = {
    width = vim.fn.winwidth(src_winid),
    height = vim.fn.winheight(src_winid),
    row = screen_pos[1],
    col = screen_pos[2],
  }
  local content_size = {
    width = width,
    height = #lines,
  }
  local view_options = to_view_options(
    configs.options,
    self.name,
    win_size,
    content_size
  )
  view_options.winoptions = self:_get_win_options(configs)
  self.winid = self._view:open(self._buffer, view_options)
  local lnum = self:_on_opened(self.winid, self._buffer, self._items, configs)

  -- define key mappings (overwrite)
  self._mappings = self._view:define_mappings(
    configs.mappings,
    [[require('vfiler/extensions/extension')._do_action]]
  )

  -- register events
  for group, eventlist in pairs(configs.events) do
    self._buffer:register_events(
      group,
      eventlist,
      [[require('vfiler/extensions/extension')._handle_event]]
    )
  end

  -- draw line texts and syntax
  self:_on_draw(self._buffer, lines)
  core.cursor.winmove(self.winid, lnum)

  -- add extension table
  extensions[self._buffer.number] = self

  -- link to filer
  self._filer._context.extension = self
end

function Extension:restart()
  self:_close()
  self:start()
end

function Extension:_close()
  local bufnr = self._buffer.number
  -- guard duplicate calls
  if not (self._view and extensions[bufnr]) then
    return false
  end
  extensions[bufnr] = nil

  cmdline.clear_prompt()
  self._view:close()
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

function Extension:_get_buf_options(configs)
  return {}
end

function Extension:_get_win_options(configs)
  return {
    number = false,
  }
end

return Extension
