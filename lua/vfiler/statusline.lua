local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

-- TODO: Generalization of status line.
--M.configs = {
--  left = {
--    { 'name' },
--    { 'path' },
--  },
--  right = {
--    { 'itemnum', 'path' },
--  },
--  separator = '',
--  subseparator = '|',
--}
--
--local component_table = {
--  name = function()
--    local name = vim.fn.expand('%')
--    return name, vim.fn.strwidth(name)
--  end,
--
--  path = function(context)
--    local path = ('[in] %s'):format(
--      core.path.escape(vim.fn.fnamemodify(context.root.path, ':~'))
--    )
--    return path, vim.fn.strwidth(path)
--  end,
--
--  itemnum = function(context)
--    local offset = 0
--    local num = vim.fn.line('$')
--    if context.header then
--      num = num - 1
--      offset = 1
--    end
--
--    local digit = 0
--    while num > 0 do
--      digit = digit + 1
--      num = math.modf(num / 10)
--    end
--
--    local itemnum = ([[%%%d{line('.')-%d}/%%{line('$')-%d}]]):format(
--      digit,
--      offset,
--      offset
--    )
--    return itemnum, (digit * 2) + 3
--  end,
--}
--
--local separator_width = vim.fn.strwidth(M.configs.separator)
--local subseparator_width = vim.fn.strwidth(M.configs.subseparator)

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
