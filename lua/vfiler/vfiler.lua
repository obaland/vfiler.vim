local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Context = require 'vfiler/context'
local Buffer = require 'vfiler/buffer'
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
      maxnr = math.max(vfiler.localnr, maxnr)
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
    vfiler.context:delete()
  end
  vfilers[bufnr] = nil
end

function VFiler.duplicate(bufnr)
  local source = vfilers[bufnr]
  local vfiler = source.object

  local bufname, name, localnr = generate_name(source.name)
  local buffer = Buffer.new(bufname)

  return VFiler._create(
    name, localnr,
    vfiler.context:duplicate(buffer),
    View.new(vfiler.context.configs.columns)
    )
end

---@param name string
function VFiler.find(name)
  local tabpagenr = vim.fn.tabpagenr()
  for _, vfiler in pairs(vfilers) do
    if tabpagenr == vfiler.tabpagenr and name == vfiler.name then
      return vfiler.object
    end
  end
  return nil
end

---@param bufnr number Buffer number
function VFiler.get(bufnr)
  return vfilers[bufnr].object
end

function VFiler.new(configs)
  local bufname, name, localnr = generate_name(configs.name)
  local buffer = Buffer.new(bufname)

  return VFiler._create(
    name, localnr,
    Context.new(buffer, configs),
    View.new(configs.columns)
    )
end

function VFiler._create(name, localnr, context, view)
  local object = setmetatable({
      context = context,
      view = view,
    }, VFiler)

  -- add vfiler resource
  vfilers[context.buffer.number] = {
    object = object,
    name = name,
    localnr = localnr,
    tabpagenr = vim.fn.tabpagenr(),
  }
  return object
end

return VFiler
