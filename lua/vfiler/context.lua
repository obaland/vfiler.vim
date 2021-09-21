local core = require 'vfiler/core'
local vim = require "vfiler/vim"
local Directory = require 'vfiler/items/directory'
local File = require 'vfiler/items/file'

local Context = {}
Context.__index = Context

function Context.new(configs)
  return setmetatable({
      items = {},
      path = '',
      visible_hidden_files = false,
      configs = core.deepcopy(configs),
    }, Context)
end

function Context:switch(path)
  local target_path = path .. (self.visible_hidden_files and '/.*' or '/*')
  for _, p in ipairs(vim.fn.glob(target_path, 1, 1)) do
    local normalized_path = core.normalized_path(p)
    local ftype = vim.fn.getftype(normalized_path)

    local item = nil
    if ftype == 'dir' then
      item = Directory.new(normalized_path, 0, false)
    elseif ftype == 'file' then
      item = File.new(normalized_path, 0, false)
    elseif ftype == 'link' then
      if vim.fn.isdirectory(normalized_path) then
        item = Directory.new(normalized_path, 0, true)
      else
        item = File.new(normalized_path, 0, true)
      end
    else
      core.warning('Unknown file type. (' .. ftype .. ')')
    end
    table.insert(self.items, item)
  end
  self.path = path
end

return Context
