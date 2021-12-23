local core = require('vfiler/core')
local event = require('vfiler/event')
local vim = require('vfiler/vim')

local extensions = {}

local Extension = {}
Extension.__index = Extension

local function winvalue(value, win_value, content_value, min, max)
  local result = 0
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
  local voptions = {}
  if options.floating then
    voptions.layout = 'floating'

    local floating = options.floating
    local minwidth = floating.minwidth or 1
    local minheight = floating.minheight or 1

    voptions.width = winvalue(
      floating.width, win_size.width, content_size.width,
      minwidth, win_size.width
    )
    voptions.height = winvalue(
      floating.height, win_size.height, content_size.height,
      minheight, win_size.height
    )
    if floating.relative then
      voptions.relative = floating.relative
    end
  elseif options.top or options.bottom then
    voptions.layout = options.top and 'top' or 'bottom'
    local value = options.top or options.bottom
    voptions.width = 0
    voptions.height = winvalue(
      value, win_size.height, content_size.height, 1, win_size.height
    )
  elseif options.right or options.left then
    voptions.layout = options.right and 'right' or 'left'
    local value = options.right or options.left
    voptions.width = winvalue(
      value, win_size.width, content_size.width, 1, win_size.width
    )
    voptions.height = 0
  end

  voptions.name = name
  -- '2' is space width
  voptions.width = math.max(vim.fn.strwidth(name) + 2, voptions.width)

  return voptions
end

local function new_view(options)
  local view = nil
  if options.floating then
    if core.is_nvim then
      view = require('vfiler/extensions/views/floating')
    else
      view = require('vfiler/extensions/views/popup')
    end
  else
    view = require('vfiler/extensions/views/window')
  end
  return view.new()
end

function Extension.new(filer, name, configs, options)
  local self = setmetatable({
    name = name,
    _source_bufnr = vim.fn.bufnr(),
    _configs = core.table.copy(configs),
    _filer = filer,
    _items = nil,
    _view = nil,
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
  local action = ext._configs.mappings[key]
  if not action then
    core.message.error('Not defined in the key')
    return
  end
  ext:do_action(action)
end

function Extension._handle_event(bufnr, type)
  local ext = Extension.get(bufnr)
  if ext then
    local action = ext._configs.events[type]
    if not action then
      core.message.error('Event "%s" is not registered.', type)
      return
    end
    ext:do_action(action)
  end
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
  -- guard duplicate calls
  if not extensions[self._view.bufnr] then
    return
  end
  extensions[self._view.bufnr] = nil

  vim.command('echo') -- Clear prompt message
  self._view:close()
  if self.on_quit then
    self._filer:do_action(self.on_quit)
  end

  local source_winnr = vim.fn.bufwinnr(self._source_bufnr)
  if source_winnr >= 0 then
    core.window.move(source_winnr)
  end

  -- unlink
  self._filer._context.extension = nil
end

function Extension:redraw()
  self._items = self:_on_update_items(self._configs)
  local lines = self:_on_get_lines(self._items)
  self:_on_draw(self._view, lines)
end

function Extension:start()
  self._items = self:_on_initialize_items(self._configs)
  local lines, width = self:_on_get_lines(self._items)

  -- to view options
  self._view = new_view(self._configs.options)
  local source_winid = self._view.source_winid
  local win_size = {
    width = vim.fn.winwidth(source_winid),
    height = vim.fn.winheight(source_winid),
  }
  local content_size = {
    width = width,
    height = #lines,
  }
  local view_options = to_view_options(
    self._configs.options, self.name, win_size, content_size
  )
  view_options.bufoptions = self:_on_set_buf_options(self._configs)
  view_options.winoptions = self:_on_set_win_options(self._configs)
  self._view:open(lines, view_options)

  self.winid = self._view.winid
  local bufnr = self._view.bufnr
  local lnum = self:_on_start(
    self.winid, bufnr, self._items, self._configs
  )

  -- define key mappings (overwrite)
  self._configs.mappings = self._view:define_mapping(
    self._configs.mappings,
    [[require('vfiler/extensions/extension')._do_action]]
  )

  -- register events
  event.register(
    'vfiler_extension', bufnr, self._configs.events,
    [[require('vfiler/extensions/extension')._handle_event]]
  )

  -- draw line texts and syntax
  self:_on_draw(self._view, lines)
  core.cursor.winmove(self.winid, lnum)

  -- add extension table
  extensions[bufnr] = self

  -- link to filer
  self._filer._context.extension = self
end

function Extension:_on_initialize_items(configs)
  -- Not implemented
  return {}
end

function Extension:_on_update_items(configs)
  -- Not implemented
  return {}
end

function Extension:_on_set_buf_options(configs)
  -- Not implemented
  return {}
end

function Extension:_on_set_win_options(configs)
  -- Not implemented
  return {}
end

function Extension:_on_start(winid, bufnr, items, configs)
  -- Not implemented
  return 1
end

function Extension:_on_get_lines(items, winwidth)
  return nil
end

function Extension:_on_draw(view, lines)
  -- Not implemented
end

return Extension
