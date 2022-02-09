local core = require('vfiler/libs/core')
local status = require('vfiler/status')
local vim = require('vfiler/libs/vim')

local Buffer = require('vfiler/buffer')
local View = require('vfiler/view')

local vfilers = {}

local VFiler = {}
VFiler.__index = VFiler

local function new_buffer(bufname, context)
  local buffer = Buffer.new(bufname)
  buffer:set_options({
    bufhidden = 'hide',
    buflisted = context.options.buflisted,
    buftype = 'nofile',
    filetype = 'vfiler',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
  })
  return buffer
end

local function generate_bufname(name)
  local bufname = 'vfiler'
  if #name > 0 then
    bufname = bufname .. ':' .. name
  end

  local maxnr = -1
  for _, vfiler in pairs(vfilers) do
    local object = vfiler.object
    if name == object._context.options.name then
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

--- Exists vfiler buffer
function VFiler.exists(bufnr)
  return vfilers[bufnr] ~= nil
end

--- Find the currently valid filer by name
---@param name string
function VFiler.find(name)
  local finded = VFiler.find_visible(name)
  if not finded then
    return VFiler.find_hidden(name)
  end
  return finded
end

--- Find the currently hidden filer by name
---@param name string
function VFiler.find_hidden(name)
  -- in hidden buffers
  for bufnr, vfiler in pairs(vfilers) do
    local object = vfiler.object
    local options = object._context.options
    local infos = vim.list.from(vim.fn.getbufinfo(bufnr))
    if (options.name == name) and (infos[1].hidden == 1) then
      return object
    end
  end
  return nil -- not found
end

--- Find the currently visible filer by name
---@param name string
function VFiler.find_visible(name)
  -- in tabpage
  for bufnr, vfiler in pairs(vfilers) do
    local object = vfiler.object
    local options = object._context.options
    if (options.name == name) and (vim.fn.bufwinnr(bufnr) >= 0) then
      return object
    end
  end
  return nil -- not found
end

--- Get the filer from the buffer number
---@param bufnr number Buffer number
function VFiler.get(bufnr)
  if not vfilers[bufnr] then
    return nil
  end
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
  -- create buffer
  local bufname, number = generate_bufname(context.options.name)
  local buffer = new_buffer(bufname, context)
  buffer:set_option('buflisted', context.options.listed)

  local self = setmetatable({
    _buffer = buffer,
    _context = context,
    _view = View.new(context),
    _mappings = nil,
    _events = nil,
  }, VFiler)

  -- add vfiler resource
  vfilers[buffer.number] = {
    object = self,
    number = number,
  }
  return self
end

function VFiler._do_action(bufnr, key)
  local vfiler = VFiler.get(bufnr)
  local action = vfiler._mappings[key]
  assert(action, 'Not defined in the key')
  vfiler:do_action(action)
end

function VFiler._handle_event(bufnr, group, type)
  local vfiler = VFiler.get(bufnr)
  if not vfiler then
    return
  end
  local events = vfiler._events[group]
  if not events then
    core.message.error('Event group "%s" is not registered.', group)
    return
  end
  local action = events[type]
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

--- Copy the vfiler
function VFiler:copy()
  local options = self._context.options
  local newcontext = self._context:copy()
  local new = VFiler.find_hidden(options.name)
  if new then
    new:unlink()
    new:update(newcontext)
  else
    new = VFiler.new(newcontext)
  end
  return new
end

--- Focus filer
function VFiler:focus()
  local winid = self._view:winid()
  if vim.fn.win_id2win(winid) ~= 0 then
    core.window.move(winid)
  end
end

--- Get root item
function VFiler:get_root_item()
  return self._context.root
end

--- Link with the specified filer
function VFiler:link(vfiler)
  self._context.linked = vfiler
  vfiler._context.linked = self
end

--- Open filer
function VFiler:open(layout)
  self._view:open(self._buffer, layout)
  self:_define_mappings()
  self:_register_events()
end

--- Quit filer
---@param force boolean
function VFiler:quit(force)
  force = force or false
  local bufnr = self._buffer.number
  if bufnr <= 0 then
    return
  end
  if force or self._context.options.quit then
    self._view:close()
    self._buffer:wipeout()
    self:unlink()
    vfilers[bufnr] = nil
  end
end

--- Set size
function VFiler:set_size(width, height)
  local options = self._context.options
  options.width = width
  options.height = height
  self._view:set_size(width, height)
end

--- Start the filer
---@param dirpath string
function VFiler:start(dirpath)
  self._context:switch(dirpath, function()
    self:draw()
    core.cursor.move(self._view:top_lnum())
  end)
end

--- Get current status string
function VFiler:status()
  return status.status(self._context, self._view)
end

--- Get current status string for statusline
function VFiler:statusline()
  return status.statusline(self._context, self._view)
end

--- Synchronize to the vfiler
---@param context table
function VFiler:sync(context, on_completed)
  self._context:sync(context, on_completed)
end

--- Unlink filer
function VFiler:unlink()
  local vfiler = self._context.linked
  if vfiler then
    vfiler._context.linked = nil
  end
  self._context.linked = nil
end

--- Update from context
function VFiler:update(context)
  self._context = context
  -- Save the status quo
  local current = self._view:get_current()
  if current then
    self._context:save(current.path)
  end

  -- set buffer options
  self._buffer:set_option('buflisted', context.options.listed)
  self._view:reset(context)
end

function VFiler:_define_mappings()
  self._mappings = self._buffer:define_mappings(
    self._context.mappings,
    [[require('vfiler/vfiler')._do_action]]
  )
end

function VFiler:_register_events()
  self._events = {}
  for group, events in pairs(self._context.events) do
    self._events[group] = self._buffer:register_events(
      group,
      events,
      [[require('vfiler/vfiler')._handle_event]]
    )
  end
end

return VFiler
