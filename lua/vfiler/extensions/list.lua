local core = require 'vfiler/core'
local mapping = require 'vfiler/mapping'
local vim = require 'vfiler/vim'

local Extension = require 'vfiler/extensions/extension'
local ExtensionList = {}

mapping.setup {
  list = {
    ['q'] = [[:lua require'vfiler/extensions/action'.quit()<CR>]],
  },
}

function ExtensionList.new(name, ...)
  return core.inherit(ExtensionList, Extension, name, ...)
end

function ExtensionList:_on_mapping()
  mapping.define('list')
end

return ExtensionList
