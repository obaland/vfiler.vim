local core = require 'vfiler/core'
local vim = require "vfiler/vim"
local Item = require 'vfiler/Item'

local Context = {}
Context.__index = Context

function Context.new(buffer, configs)
  local object = setmetatable({
      buffer = buffer,
      items = {},
      path = configs.path,
      visible_hidden_files = false,
    }, Context)
  object:switch(configs.path)
  return object
end

function Context:switch(path)
  local target_path = path .. (self.visible_hidden_files and '/.*' or '/*')
  for _, p in pairs(vim.fn.glob(target_path, 1, 1)) do
    table.insert(self.items, Item.new(core.normalized_path(p), 1))
  end
end

return Context
