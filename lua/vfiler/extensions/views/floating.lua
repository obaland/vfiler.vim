local core = require 'vfiler/core'

local Window = require 'vfiler/extensions/views/window'

local Floating = {}

function Floating.new(configs)
  return core.inherit(Floating, Window, configs)
end

function Floating:open(name, texts)
end

function Floating:draw(texts, ...)
end
