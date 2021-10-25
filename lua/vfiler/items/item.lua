local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

function Item.new(path, islink)
  local isdirectory = vim.fn.isdirectory(path) == 1
  local mods = isdirectory and ':h:t' or ':t'

  local size = vim.fn.getfsize(path)
  local time = vim.fn.getftime(path)
  if size < 0 or time < 0 then
    core.error(('Failed - Invalid path (%s)'):format(path))
    return nil
  end

  return setmetatable({
      isdirectory = isdirectory,
      islink = islink,
      level = 0,
      name = vim.fn.fnamemodify(path, mods),
      parent = nil,
      path = path,
      selected = false,
      size = size,
      time = time,
      mode = vim.fn.getfperm(path)
    }, Item)
end

return Item
