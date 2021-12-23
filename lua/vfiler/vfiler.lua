local core = require('vfiler/core')
local event = require('vfiler/event')
local mapping = require('vfiler/mapping')
local vim = require('vfiler/vim')

local View = require('vfiler/view')

local vfilers = {}

local VFiler = {}
VFiler.__index = VFiler

local function define_mappings(bufnr, mappings)
  return mapping.define(
    bufnr, mappings, [[require('vfiler/vfiler')._do_action]]
  )
end

local function generate_bufname(name)
  local bufname = 'vfiler'
  if #name > 0 then
    bufname = bufname .. ':' .. name
  end

  local maxnr = -1
  for _, vfiler in pairs(vfilers) do
    local object = vfiler.object
    if name == object._context.name then
      maxnr = math.max(vfiler.number, maxnr)
    end
  end

  local number = 0
  if maxnr >= 0 then
    number = maxnr + 1
    bufname = bufname .. '-' .. tostring(number)
  end
  return bufname, number
end

--- Cleanup vfiler buffers
function VFiler.cleanup()
  local valid_filers = {}
  for bufnr, vfiler in pairs(vfilers) do
    local exists = vim.fn.bufexists(bufnr) and vim.fn.bufloaded(bufnr)
    if exists then
      valid_filers[bufnr] = vfiler
    else
      vim.command('bwipeout ' .. bufnr)
    end
  end
  vfilers = valid_filers
end

--- Find the currently valid filer by name
---@param name string
function VFiler.find(name)
  -- in tabpage
  for bufnr, vfiler in pairs(vfilers) do
    local object = vfiler.object
    if (object._context.name == name) and (vim.fn.bufwinnr(bufnr) >= 0) then
      return object
    end
  end
  return VFiler.find_hidden(name)
end

--- Find the currently hidden filer by name
---@param name string
function VFiler.find_hidden(name)
  -- in hidden buffers
  for bufnr, vfiler in pairs(vfilers) do
    local object = vfiler.object
    local infos = vim.from_vimlist(vim.fn.getbufinfo(bufnr))
    if (object._context.name == name) and (infos[1].hidden == 1) then
      return object
    end
  end
  return nil -- not found
end

--- Get the filer from the buffer number
---@param bufnr number Buffer number
function VFiler.get(bufnr)
  return vfilers[bufnr].object
end

--- Get the filer of the current buffer
function VFiler.get_current()
  return VFiler.get(vim.fn.bufnr())
end

--- Get the currently displayed filers
function VFiler.get_displays()
  local filers = {}
  for bufnr, filer in pairs(vfilers) do
    if vim.fn.winnr(bufnr) >= 0 then
      table.insert(filers, filer.object)
    end
  end
  return filers
end

--- Create a filer obuject
---@param context table
function VFiler.new(context)
  local bufname, number = generate_bufname(context.name)
  local view = View.new(bufname, context)

  -- register events
  event.register(
    'vfiler', view.bufnr, context.events,
    [[require('vfiler/vfiler')._handle_event]]
  )

  local object = setmetatable({
    _context = context,
    _view = view,
    _defined_mappings = define_mappings(view.bufnr, context._mappings),
  }, VFiler)

  -- add vfiler resource
  vfilers[view.bufnr] = {
    object = object,
    number = number,
  }
  return object
end

function VFiler._do_action(bufnr, key)
  local vfiler = VFiler.get(bufnr)
  local action = vfiler._defined_mappings[key]
  if not action then
    core.message.error('Not defined in the key')
    return
  end
  vfiler:do_action(action)
end

function VFiler._handle_event(bufnr, type)
  local vfiler = VFiler.get(bufnr)
  local action = vfiler._context._events[type]
  if not action then
    core.message.error('Event "%s" is not registered.', type)
    return
  end
  vfiler:do_action(action)
end

--- Is the filer displayed?
function VFiler:displayed()
  return self._view:winnr() >= 0
end

--- Do action
function VFiler:do_action(action, ...)
  action(self, self._context, self._view, ...)
end

--- Draw the filer in the current window
function VFiler:draw()
  self._view:draw(self._context)
end

--- Duplicate the vfiler
function VFiler:duplicate()
  local newcontext = self._context:duplicate()
  return VFiler.new(newcontext)
end

--- Get root item
function VFiler:get_root_item()
  return self._context.root
end

--- Get current status (for statusline)
function VFiler:get_status()
  if not self._context then
    return ''
  end
  return self._context.status
end

--- Link with the specified filer
function VFiler:link(vfiler)
  self._context.linked = vfiler
  vfiler._context.linked = self
end

--- Open filer
function VFiler:open(...)
  local winnr = self._view:winnr()
  if winnr >= 0 then
    core.window.move(winnr)
    return
  end

  local layout = ...
  if layout and layout ~= 'edit' then
    core.window.open(layout)
  end
  self._view:open()
end

--- Quit filer
function VFiler:quit()
  local bufnr = self._view.bufnr
  if self._context.quit and bufnr >= 0 then
    self._view:delete()
    self:unlink()
    vfilers[bufnr] = nil
  end
end

--- Reset
---@param context table
function VFiler:reset(context)
  -- clear the data so far
  self:unlink()
  mapping.undefine(self._context._mappings)

  self._context:reset(context)
  self._view:reset(context)
  self._defined_mappings = define_mappings(
    self._view.bufnr, context._mappings
  )
end

--- Start the filer
---@param dirpath string
function VFiler:start(dirpath)
  self._context:switch(dirpath)
  self:draw()
  core.cursor.move(self._view:top_lnum())
end

--- Synchronize to the vfiler
---@param context table
function VFiler:sync(context)
  self._context:sync(context)
end

--- Unlink filer
function VFiler:unlink()
  local vfiler = self._context.linked
  if vfiler then
    vfiler._context.linked = nil
  end
  self._context.linked = nil
end

return VFiler
