local core = require 'vfiler/core'

local Directory = {}

function Directory.new(path, level, islink)
  local Item = require('vfiler/items/item')
  local self = core.inherit(Directory, Item, path, level, islink)
  self.type = self.islink and 'L' or 'D'
  return self
end

return Directory
