local core = require('vfiler/core')
local event = require('vfiler/event')
local vim = require('vfiler/vim')

local extensions = {}

local Extension = {}
Extension.__index = Extension

function Extension.new(filer, name, view, configs)
  return setmetatable({
    source_bufnr = vim.fn.bufnr(),
    configs = core.table.copy(configs),
    filer = filer,
    items = nil,
    name = name,
    bufnr = 0,
    winid = 0,
    view = view,
  }, Extension)
end

function Extension.create_view(options)
  local view = nil
  if options.floating then
    if vim.fn.has('nvim') == 1 then
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
  ext:do_action(key)
end

function Extension._handle_event(bufnr, type)
  local ext = Extension.get(bufnr)
  if ext then
    ext:handle_event(type)
  end
end

---@param key string
function Extension:do_action(key)
  local func = self.configs.mappings[key]
  if not func then
    core.message.error('Not defined in the key')
    return
  end
  func(self)
end

function Extension:handle_event(type)
  local events = self.configs.events
  local func = events[type]
  if not func then
    core.message.error('Event "%s" is not registered.', type)
    return
  end
  func(self)
end

function Extension:quit()
  -- guard duplicate calls
  if not extensions[self.bufnr] then
    return
  end
  extensions[self.bufnr] = nil

  vim.command('echo') -- Clear prompt message
  self.view:close()
  if self.on_quit then
    self.on_quit(self.filer)
  end

  local source_winnr = vim.fn.bufwinnr(self.source_bufnr)
  if source_winnr >= 0 then
    core.window.move(source_winnr)
  end

  -- unlink
  self.filer.context.extension = nil
end

function Extension:start(items, ...)
  local lnum = 1
  if ... then
    local default = ...
    for i, item in ipairs(items) do
      if item == default then
        lnum = i
        break
      end
    end
  end

  local texts = self:_on_get_texts(items)
  self.winid = self.view:open(self.name, texts)
  self.bufnr = vim.fn.winbufnr(self.winid)
  self.items = items

  -- define key mappings (overwrite)
  self.configs.mappings = self.view:define_mapping(
    self.configs.mappings,
    [[require('vfiler/extensions/extension')._do_action]]
    )

  -- register events
  event.register(
    'vfiler_extension', self.bufnr, self.configs.events,
    [[require('vfiler/extensions/extension')._handle_event]]
    )

  -- draw line texts and syntax
  self:_on_draw(texts)
  vim.fn.win_execute(self.winid, ('call cursor(%d, 1)'):format(lnum))

  -- add extension table
  extensions[self.bufnr] = self

  -- link to filer
  self.filer.context.extension = self
end

function Extension:_on_get_texts(items)
  return nil
end

function Extension:_on_draw(texts)
  -- Not implemented
end

return Extension
