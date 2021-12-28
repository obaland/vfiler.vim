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
  return ('%s%s%s%s%s%s%s'):format(
    '%#StatusLine#', margin,
    '%#vfilerStatusLine_ChooseWindowKey#', padding, key, padding,
    '%#StatusLine#'
  )
end

--- Status line string for status
---@param winwidth number
---@param context table
function M.status(winwidth, context)
  local name = ' ' .. vim.fn.expand('%') .. ' '
  local path = (' [in] %s '):format(
    core.path.escape(vim.fn.fnamemodify(context.root.path, ':~'))
  )
  local status = {'%#StatusLine#', path}
  local strwidth = vim.fn.strwidth
  if (strwidth(name) + strwidth(path)) <= winwidth then
    table.insert(status, 1, name)
    table.insert(status, 1, '%#vfilerStatusLine_Name#')
  end
  return table.concat(status, '')
end

return M
