local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Ext = require 'vfiler/exts/ext'

local ExtList = {}

function ExtList.new(name, ...)
  return core.inherit(ExtList, Ext, name, ...)
end

function ExtList:_on_mapping()
  self:_define_keymaps {
    ['q'] = [[:lua require'vfiler/extensions/action'.quit()<CR>]],
  }
end

return ExtList
