local core = require('vfiler/core')
local vim = require('vfiler/vim')

local M = {}

--- Status line for choose window key display
---@param winwidth number
---@param key string
function M.choose_window_key(winwidth, key)
  local caption_width = winwidth / 4
  local padding = (' '):rep(math.ceil(caption_width / 2))
  local margin = (' '):rep(math.ceil((winwidth - caption_width) / 2))
  local status = {
    '%#vfilerStatusLine#',
    margin,
    '%#vfilerStatusLineSection#',
    padding,
    key,
    padding,
    '%#vfilerStatusLine#',
  }
  return table.concat(status, '')
end

--- Status line string for status
---@param context table
function M.status(winwidth, context)
  local status = {}

  -- number of items, and current item number
  local offset = 0
  local num = vim.fn.line('$')
  if context.header then
    num = num - 1
    offset = 1
  end

  local digit = 0
  while num > 0 do
    digit = digit + 1
    num = math.modf(num / 10)
  end

  local num_items = ([[ %%%d{line('.')-%d}/%%{line('$')-%d} ]]):format(
    digit,
    offset,
    offset
  )
  table.insert(status, '%=%#vfilerStatusLineSection#')
  table.insert(status, num_items)
  local width = (digit * 2) + 3

  -- current root path
  local path = (' [in] %s '):format(
    core.path.escape(vim.fn.fnamemodify(context.root.path, ':~'))
  )
  width = width + vim.fn.strwidth(path)
  if width <= winwidth then
    table.insert(status, 1, path)
    table.insert(status, 1, '%#vfilerStatusLine#')
  end

  -- filer name
  local name = (' %s '):format(vim.fn.expand('%'))
  width = width + vim.fn.strwidth(name)
  if width <= winwidth then
    table.insert(status, 1, name)
    table.insert(status, 1, '%#vfilerStatusLineSection#')
  end
  return table.concat(status, '')
end

return M
