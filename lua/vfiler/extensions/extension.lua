local core = require('vfiler/core')
local event = require('vfiler/event')
local vim = require('vfiler/vim')

local extensions = {}

local Extension = {}
Extension.__index = Extension

function Extension.new(filer, name, view, configs, options)
  local self = setmetatable({
    name = name,
    bufnr = 0,
    winid = 0,
    _source_bufnr = vim.fn.bufnr(),
    _configs = core.table.copy(configs),
    _filer = filer,
    _items = nil,
    _options = core.table.copy(configs),
    _view = view,
  }, Extension)
  -- set options
  for key, value in pairs(options) do
    self[key] = value
  end
  return self
end

function Extension.create_view(options)
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
  return view.new(options)
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

--- Get the number of line in the view buffer
function Extension:num_lines()
  return #self._items
end

function Extension:quit()
  -- guard duplicate calls
  if not extensions[self.bufnr] then
    return
  end
  extensions[self.bufnr] = nil

  vim.command('echo') -- Clear prompt message
  self._view:close()
  if self.on_quit then
    self.on_quit(self._filer)
  end

  local source_winnr = vim.fn.bufwinnr(self._source_bufnr)
  if source_winnr >= 0 then
    core.window.move(source_winnr)
  end

  -- unlink
  self._filer._context.extension = nil
end

function Extension:draw()
  local texts = self:_on_get_texts(self._items)
  self:_on_draw(self._view, texts)
end

function Extension:start()
  self._items = self:_on_create_items(self._configs)
  local texts = self:_on_get_texts(self._items)
  self.winid = self._view:open(self.name, texts)
  self.bufnr = vim.fn.winbufnr(self.winid)
  local lnum = self:_on_start(
    self.winid, self.bufnr, self._items, self._configs
  )

  -- define key mappings (overwrite)
  self._configs.mappings = self._view:define_mapping(
    self._configs.mappings,
    [[require('vfiler/extensions/extension')._do_action]]
  )

  -- register events
  event.register(
    'vfiler_extension', self.bufnr, self._configs.events,
    [[require('vfiler/extensions/extension')._handle_event]]
  )

  -- draw line texts and syntax
  self:draw()
  vim.fn.win_execute(self.winid, ('call cursor(%d, 1)'):format(lnum))

  -- add extension table
  extensions[self.bufnr] = self

  -- link to filer
  self._filer._context.extension = self
end

function Extension:_on_create_items(configs)
  -- Not implemented
  return {}
end

function Extension:_on_start(winid, bufnr, items, configs)
  -- Not implemented
  return 1
end

function Extension:_on_get_texts(items)
  return nil
end

function Extension:_on_draw(view, texts)
  -- Not implemented
end

return Extension
