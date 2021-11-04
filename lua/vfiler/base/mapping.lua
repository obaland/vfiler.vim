local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Mapping = {}
Mapping.__index = Mapping

function Mapping.new()
  return setmetatable({
      keymappings = {},
      path = nil,
    }, Mapping)
end

function Mapping:_call(key, bufnr)
  local func = self.keymappings[key]
  if not func then
    core.error('No function is defined to key "%s"', key)
    return
  end
  self.do_action(bufnr, func)
end

function Mapping:define(bufnr)
  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }
  for key, _ in pairs(self.keymappings) do
    local rhs = (
      [[lua: require('%s'):_call('%s', %d')<CR>]]
      ):format(self.path, key, bufnr)
    vim.set_buf_keymap('n', key, rhs, options)
  end
end

function Mapping:_setup(keymaps, path)
  core.merge_table(self.keymappings, keymaps)
  self.path = path
end

function Mapping.do_action(bufnr, func)
  core.error('Not implemented')
end

return Mapping
