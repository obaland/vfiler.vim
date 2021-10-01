local core = require 'vfiler/core'

local Extension = require 'vfiler/extensions/extension'

local List = {}

function List.new(name)
  return core.inherit(List, Extension, name)
end

return List
