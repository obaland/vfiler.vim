local Context = require 'vfiler/context'
local Buffer = require 'vfiler/buffer'
local View = require 'vfiler/view'
local vim = require 'vfiler/vim'

local repository_table = {}

local M = {}

function M.create(configs)
  local buffer = Buffer.new(configs.name)
  local source = {
    context = Context.new(buffer, configs),
    view = View.new()
  }
  repository_table[buffer.number] = source
  return source
end

function M.get(name)
  local tabpagenr = vim.fn.tabpagenr()
  for _, source in pairs(repository_table) do
    local buffer = source.context.buffer
    if tabpagenr == buffer._tabpagenr and name == buffer.name then
      return source
    end
  end
  return nil
end

return M
