local core = require 'vfiler/core'
local Item = require 'vfiler/items/item'

local File = {}

function File.new(path, level, islink)
  local self = core.inherit(File, Item, path, level, islink)
  return self
end

return File
