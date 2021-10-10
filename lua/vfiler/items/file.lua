local core = require 'vfiler/core'

local File = {}

function File.new(path, level, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(File, Item, path, level, islink)
  self.type = self.islink and 'L' or 'F'
  return self
end

return File
