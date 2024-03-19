local core = require('vfiler/libs/core')
local event = require('vfiler/events/event')
local status = require('vfiler/status')
local vim = require('vfiler/libs/vim')

local vfiler_objects = {}

local VFiler = {}
VFiler.__index = VFiler

local function new_buffer(bufname, context)
  local Buffer = require('vfiler/buffer')
  local buffer = Buffer.new(bufname, {
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
  for _, vfiler in pairs(vfiler_objects) do
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
  for bufnr, vfiler in pairs(vfiler_objects) do
    local exists = vim.fn.bufexists(bufnr) and vim.fn.bufloaded(bufnr)
    if exists then
      valid_filers[bufnr] = vfiler
    else
      vim.command('bwipeout ' .. bufnr)
    end
  end
  vfiler_objects = valid_filers
end

--- Exists vfiler buffer
function VFiler.exists(bufnr)
  return vfiler_objects[bufnr] ~= nil
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
  for bufnr, vfiler in pairs(vfiler_objects) do
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
  for bufnr, vfiler in pairs(vfiler_objects) do
    local object = vfiler.object
    assert(bufnr == object._view:bufnr())
    local options = object._context.options
    if (options.name == name) and object:visible() then
      return object
    end
  end
  return nil -- not found
end

--- Do action for each visible filers
function VFiler.foreach(action, ...)
  local current = VFiler.get(vim.fn.bufnr())
  if not current then
    core.message.error(
      'The vfiler buffer dones not exist. (%d)',
      vim.fn.bufnr()
    )
    return
  end
  for _, filer in ipairs(VFiler.get_visible()) do
    filer:do_action(action, ...)
  end
end

--- Get the filer from the buffer number
---@param bufnr number: Buffer number
function VFiler.get(bufnr)
  if not vfiler_objects[bufnr] then
    return nil
  end
  return vfiler_objects[bufnr].object
end

--- Get the filer that is currently visible
function VFiler.get_visible()
  local visibilities = {}
  for bufnr, vfiler in pairs(vfiler_objects) do
    local object = vfiler.object
    assert(bufnr == object._view:bufnr())
    if object:visible() then
      table.insert(visibilities, object)
    end
  end
  return visibilities
end

--- Get the filer that is currently visible in tabpage
---@param tabpage number: Tabpage number.
--        If '0' is specified, the current tabpage.
function VFiler.get_visible_in_tabpage(tabpage)
  tabpage = (tabpage > 0) and tabpage or vim.fn.tabpagenr()
  local visibilities = {}
  for _, bufnr in ipairs(vim.fn.tabpagebuflist(tabpage)) do
    local vfiler = vfiler_objects[bufnr]
    if vfiler then
      local object = vfiler.object
      assert(bufnr == object._view:bufnr())
      if object:visible() then
        table.insert(visibilities, object)
      end
    end
  end
  return visibilities
end

--- Create a filer object
---@param context table
function VFiler.new(context)
  -- create buffer
  local bufname, number = generate_bufname(context.options.name)
  local buffer = new_buffer(bufname, context)
  buffer:set_option('buflisted', context.options.listed)

  local View = require('vfiler/view')
  local self = setmetatable({
    _buffer = buffer,
    _context = context,
    _view = View.new(context.options),
    _mappings = nil,
  }, VFiler)

  -- add vfiler resource
  vfiler_objects[buffer.number] = {
    object = self,
    number = number,
  }
  return self
end

function VFiler._do_action(bufnr, key)
  local vfiler = VFiler.get(bufnr)
  if not vfiler then
    core.message.error('The vfiler buffer dones not exist. (%d)', bufnr)
    return
  end
  local action = vfiler._mappings[key]
  assert(action, 'Not defined in the key')
  vfiler:do_action(action)
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

--- Do action
function VFiler:do_action(action, ...)
  action(self, self._context, self._view, ...)
end

--- Draw the filer in the current window
function VFiler:draw()
  self._view:draw(self._context)
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

--- Move the cursor to the specified path
function VFiler:move_cursor(path)
  self._view:move_cursor(path)
end

--- Open filer
function VFiler:open(layout)
  self._view:open(self._buffer, layout)
  self:_define_mappings()
  self:_register_events()
end

--- Quit filer
function VFiler:quit()
  local bufnr = self._buffer.number
  if bufnr <= 0 then
    return
  end
  self._view:close()
  self:unlink()
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
---@param filepath string
function VFiler:start(dirpath, filepath)
  local context = self._context
  local path = context:switch(dirpath)
  -- Find the specified path
  if filepath then
    local item = context:open_tree(filepath)
    if item then
      path = item.path
    end
  end
  self:draw()
  self._view:move_cursor(path)

  -- Reload git status
  if self._view:has_column('git') then
    context.git:reload_async(context.root.path, function()
      self._view:redraw_git(context)
    end)
  end
end

--- Get current status string
function VFiler:status()
  return status.status(self._context, self._view)
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
  self._context:update(context)
  -- Save the status quo
  local current = self._view:get_item()
  if current then
    self._context:save(current.path)
  end

  -- set buffer options
  self._buffer:set_option('buflisted', context.options.listed)
  self._view:reset(context.options)
end

--- Is the filer visible?
function VFiler:visible()
  return self._view:winid() > 0
end

--- Wipeout filer
function VFiler:wipeout()
  self:quit()
  -- wipeout buffer
  local bufnr = self._buffer.number
  if bufnr <= 0 then
    return
  end
  self:_unregister_events()
  self._buffer:wipeout()
  vfiler_objects[bufnr] = nil
end

function VFiler:_define_mappings()
  self._mappings = self._buffer:define_mappings(
    self._context.mappings,
    [[require('vfiler/vfiler')._do_action]]
  )
end

function VFiler:_register_events()
  for group, elist in pairs(self._context.events) do
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
end

function VFiler:_unregister_events()
  for group, _ in pairs(self._context.events) do
    event.unregister(group, self._buffer.number)
  end
end

return VFiler
