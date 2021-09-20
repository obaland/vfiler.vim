local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Item = {}
Item.__index = Item

local function get_ftype(path)
  local type = vim.fn.getftype(path)
  if type == 'dir' then
    return 'D'
  elseif type == 'file' then
    return 'F'
  elseif type == 'link' then
    return 'L'
  else
    core.warning('Unknown file type (' .. type .. ')')
  end
  return ''
end

function Item.new(path, ...)
  return setmetatable({
      is_directory = vim.fn.isdirectory(path),
      level = ... or 0,
      name = vim.fn.fnamemodify(path, ':t'),
      opened = false,
      path = path,
      selected = false,
      size = vim.fn.getfsize(path),
      time = vim.fn.getftime(path),
      type = get_ftype(path),
    }, Item)
end

return Item
