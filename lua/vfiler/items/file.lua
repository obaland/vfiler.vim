local core = require 'vfiler/core'

local File = {}

function File.create(path)
  return File.new(path, 0, false)
end

function File.new(path, level, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(File, Item, path, level, islink)
  self.type = self.islink and 'L' or 'F'
  return self
end

return File
