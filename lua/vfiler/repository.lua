local Context = require 'vfiler/context'
local Buffer = require 'vfiler/buffer'
local View = require 'vfiler/view'
local vim = require 'vfiler/vim'

local BUFNAME_PREFIX = 'vfiler'
local BUFNAME_SEPARATOR = '-'
local BUFNUMBER_SEPARATOR = ':'

local repository_table = {}

local M = {}

local function generate_name(name)
  local bufname = BUFNAME_PREFIX
  if name:len() > 0 then
    bufname = bufname .. BUFNAME_SEPARATOR .. name
  end

  local max_number = -1
  for _, source in pairs(repository_table) do
    if name == source._name then
      max_number = math.max(source._local_number, max_number)
    end
  end

  local number = 0
  if max_number >= 0 then
    number = max_number + 1
    bufname = bufname .. BUFNUMBER_SEPARATOR .. tostring(number)
  end
  return bufname, name, number
end

function M.create(configs)
  local bufname, name, local_number = generate_name(configs.name)
  local buffer = Buffer.new(bufname)

  repository_table[buffer.number] = {
    context = Context.new(buffer, configs),
    view = View.new(),
    _name = name,
    _local_number = local_number,
  }
  return repository_table[buffer.number]
end

function M.delete(bufnr)
  repository_table[bufnr] = nil
end

function M.find(name)
  local tabpagenr = vim.fn.tabpagenr()
  for _, source in pairs(repository_table) do
    local buffer = source.context.buffer
    if tabpagenr == buffer._tabpagenr and name == buffer.name then
      return source
    end
  end
  return nil
end

function M.get(bufnr)
  return repository_table[bufnr]
end

return M
