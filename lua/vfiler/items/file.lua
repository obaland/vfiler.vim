local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local File = {}

function File.create(path)
  -- create file
  if core.is_windows then
    os.execute('type nul > ' .. path)
  else
    os.execute('touch ' .. path)
  end
  return File.new(path, false)
end

function File.new(path, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(File, Item, path, islink)
  self.type = self.islink and 'L' or 'F'
  return self
end

return File
