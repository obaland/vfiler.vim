local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

function Item.new(path, level, islink)
  return setmetatable({
      isdirectory = vim.fn.isdirectory(path) == 1,
      islink = islink,
      level = level,
      name = vim.fn.fnamemodify(path, ':t'),
      path = path,
      opened = false,
      selected = false,
      size = vim.fn.getfsize(path),
      time = vim.fn.getftime(path),
    }, Item)
end

return Item
