local core = require('vfiler/core')
local event = require('vfiler/event')
local mapping = require('vfiler/mapping')
local vim = require('vfiler/vim')

local Context = require('vfiler/context')
local View = require('vfiler/view')

local vfilers = {}

local VFiler = {}
VFiler.__index = VFiler

local function define_mappings(bufnr, mappings)
  return mapping.define(
    bufnr, mappings, [[require('vfiler/vfiler')._do_action]]
    )
end

--- Do the action of the specified key
local function do_action(vfiler, key)
  local action = vfiler._defined_mappings[key]
  if not action then
    core.message.error('Not defined in the key')
    return
  end
  action(vfiler)
end

--- Handle the specified event
local function handle_event(vfiler, type)
  local action = vfiler.context.events[type]
  if not action then
    core.message.error('Event "%s" is not registered.', type)
    return
  end
  action(vfiler)
end

local function register_events(bufnr, events)
  event.register(
    'vfiler', bufnr, events, [[require('vfiler/vfiler')._handle_event]]
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
    if name == object.context.name then
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
    if (object.context.name == name) and (vim.fn.bufwinnr(bufnr) >= 0) then
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
    if (object.context.name == name) and (infos[1].hidden == 1) then
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

  register_events(view.bufnr, context.events)

  local object = setmetatable({
    context = context,
    view = view,
    _defined_mappings = define_mappings(view.bufnr, context.mappings),
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
  do_action(vfiler, key)
end

function VFiler._handle_event(bufnr, type)
  local vfiler = VFiler.get(bufnr)
  handle_event(vfiler, type)
end

--- Is the filer displayed?
function VFiler:displayed()
  return self.view:winnr() >= 0
end

--- Draw the filer in the current window
function VFiler:draw()
  self.view:draw(self.context)
end

--- Link with the specified filer
function VFiler:link(vfiler)
  self.context.linked = vfiler
  vfiler.context.linked = self
end

--- Open filer
function VFiler:open(...)
  local winnr = self.view:winnr()
  if winnr >= 0 then
    core.window.move(winnr)
    return
  end

  local layout = ...
  if layout and layout ~= 'edit' then
    core.window.open(layout)
  end
  self.view:open()
end

--- Quit filer
function VFiler:quit()
  local bufnr = self.view.bufnr
  if self.context.quit and bufnr >= 0 then
    self.view:delete()
    self:unlink()
    vfilers[bufnr] = nil
  end
end

--- Redraw the filer in the current window
function VFiler:redraw()
  self.view:redraw()
end

--- Reset
---@param context table
function VFiler:reset(context)
  -- clear the data so far
  self:unlink()
  mapping.undefine(self.context.mappings)

  self.context:reset(context)
  self.view:reset(context)
  self._defined_mappings = define_mappings(self.view.bufnr, context.mappings)
end

--- Start the filer
---@param dirpath string
function VFiler:start(dirpath)
  self.context:switch(dirpath)
  self:draw()
  core.cursor.move(self.view:top_lnum())
end

--- Unlink filer
function VFiler:unlink()
  local vfiler = self.context.linked
  if vfiler then
    vfiler.context.linked = nil
  end
  self.context.linked = nil
end

return VFiler
