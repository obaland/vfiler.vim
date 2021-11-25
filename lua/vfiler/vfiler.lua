local core = require 'vfiler/core'
local event = require 'vfiler/event'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Context = require 'vfiler/context'
local View = require 'vfiler/view'

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
  local func = vfiler._mappings[key]
  if not func then
    core.message.error('Not defined in the key')
    return
  end
  func(vfiler.context, vfiler.view)
end

--- Handle the specified event
local function handle_event(vfiler, type)
  local events = vfiler.configs.events
  local func = events[type]
  if not func then
    core.message.error('Event "%s" is not registered.', type)
    return
  end
  func(vfiler.context, vfiler.view)
end

local function register_events(bufnr, events)
  event.register(
    'vfiler', bufnr, events, [[require('vfiler/vfiler')._handle_event]]
    )
end

local function generate_name(name)
  local bufname = 'vfiler'
  if #name > 0 then
    bufname = bufname .. ':' .. name
  end

  local maxnr = -1
  for _, vfiler in pairs(vfilers) do
    if name == vfiler.name then
      maxnr = math.max(vfiler.number, maxnr)
    end
  end

  local number = 0
  if maxnr >= 0 then
    number = maxnr + 1
    bufname = bufname .. '-' .. tostring(number)
  end
  return bufname, name, number
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
    if (vfiler.name == name) and (vim.fn.bufwinnr(bufnr) >= 0) then
      return vfiler.object
    end
  end
  return VFiler.find_hidden(name)
end

--- Find the currently hidden filer by name
---@param name string
function VFiler.find_hidden(name)
  -- in hidden buffers
  for bufnr, vfiler in pairs(vfilers) do
    local infos = vim.from_vimdict(vim.fn.getbufinfo(bufnr))
    if (vfiler.name == name) and (infos[1].hidden == 1) then
      return vfiler.object
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
---@param configs table
function VFiler.new(configs)
  local options = configs.options
  local bufname, name, number = generate_name(options.name)
  local view = View.new(bufname, options)
  local bufnr = view:create()

  register_events(bufnr, configs.events)

  local object = setmetatable({
    configs = core.table.copy(configs),
    context = Context.new(options),
    view = view,
    _mappings = define_mappings(bufnr, configs.mappings),
  }, VFiler)

  -- add vfiler resource
  vfilers[bufnr] = {
    object = object,
    name = name,
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
  if self:displayed() then
    core.window.move(self.view:winnr())
    return
  end

  local direction = ...
  if direction and direction ~= 'edit' then
    core.window.open(direction)
  end
  self.view:open()
end

--- Quit filer
function VFiler:quit()
  local bufnr = self.view.bufnr
  if self.configs.options.quit and bufnr >= 0 then
    self.view:delete()
    self:unlink()
    vfilers[bufnr] = nil
  end
end

--- Reset the filer object
---@param configs table
function VFiler:reset(configs)
  self:unlink()
  self.context = Context.new(configs.options)
  self.view:reset(configs.options)

  -- reset keymapping
  mapping.undefine(self.configs.mappings)
  self._mappings = define_mappings(self.view.bufnr, configs.mappings)
  self.configs = core.table.copy(configs)
end

--- Start the filer
---@param dirpath string
function VFiler:start(dirpath)
  self.context:switch(dirpath)
  self.view:draw(self.context)
  core.cursor.move(2)
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
