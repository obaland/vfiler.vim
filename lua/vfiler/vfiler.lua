local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Context = require 'vfiler/context'
local View = require 'vfiler/view'

local BUFNAME_PREFIX = 'vfiler'
local BUFNAME_SEPARATOR = '-'
local BUFNUMBER_SEPARATOR = ':'

local vfilers = {}

local VFiler = {}
VFiler.__index = VFiler

local function generate_name(name)
  local bufname = BUFNAME_PREFIX
  if #name > 0 then
    bufname = bufname .. BUFNAME_SEPARATOR .. name
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
    bufname = bufname .. BUFNUMBER_SEPARATOR .. tostring(number)
  end
  return bufname, name, number
end

function VFiler.delete(bufnr)
  local vfiler = VFiler.get(bufnr)
  if vfiler then
    vfiler:quit()
  end
  vfilers[bufnr] = nil
end

---@param name string
function VFiler.find(name)
  -- in tabpage
  local buflist = vim.from_vimlist(vim.fn.tabpagebuflist())
  for _, bufnr in ipairs(buflist) do
    local vfiler = vfilers[bufnr]
    if vfiler and vfiler.name == name then
      return vfiler.object
    end
  end

  -- in hidden buffers
  for bufnr, vfiler in pairs(vfilers) do
    if vim.fn.bufwinnr(bufnr) >= 0 and vfiler.name == name then
      return vfiler.object
    end
  end

  return nil -- not found
end

---@param bufnr number Buffer number
function VFiler.get(bufnr)
  return vfilers[bufnr].object
end

function VFiler.get_current()
  return VFiler.get(vim.fn.bufnr())
end

---@param configs table
function VFiler.new(configs)
  local options = configs.options
  local bufname, name, number = generate_name(options.name)
  local view = View.new(bufname, options)

  -- key mappings
  local mappings = mapping.define(
    view.bufnr, configs.mappings,
    [[require('vfiler/vfiler')._call]]
    )

  local object = setmetatable({
    configs = core.table.copy(configs),
    context = Context.new(options),
    linked = nil,
    mappings = mappings,
    options = core.table.copy(options),
    view = view,
  }, VFiler)

  -- add vfiler resource
  vfilers[view.bufnr] = {
    object = object,
    name = name,
    number = number,
  }
  return object
end

function VFiler._call(bufnr, key)
  local vfiler = VFiler.get(bufnr)
  vfiler:do_action(key)
end

function VFiler:do_action(key)
  local func = self.mappings[key]
  if not func then
    core.message.error('Not defined in the key')
    return
  end
  func(self.context, self.view)
end

function VFiler:link(vfiler)
  self.linked = vfiler
  vfiler.linked = self
end

function VFiler:open(...)
  local winnr = vim.fn.bufwinnr(self.view.bufnr)
  if winnr > 0 then
    core.window.move(winnr)
  else
    local direction = ...
    if type then
      -- open window
      core.window.open(direction)
    end
    self.view:open()
  end
end

function VFiler:quit()
  self.view:delete()
  self:unlink()
end

function VFiler:unlink()
  local vfiler = self.linked
  if vfiler then
    vfiler.linked = nil
  end
  self.linked = nil
end

return VFiler
