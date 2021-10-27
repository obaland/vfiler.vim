local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

M.choice = {
  YES = 1,
  NO = 2,
  CANCEL = 3,
}

function M.confirm(prompt, choices, default)
  vim.fn.confirm(prompt)
end

function M.input(prompt, ...)
  local args = ... and {...} or {}
  local text = args[1] or ''
  local completion = args[2]

  prompt = ('[vfiler] %s:'):format(prompt)

  local content = ''
  if completion then
    content = vim.fn.input(prompt, text, completion)
  else
    content = vim.fn.input(prompt, text)
  end
  vim.command('redraw')
  return content
end

function M.input_multiple(prompt, callback)
  local content = M.input(prompt .. ' (comma separated)')
  local splitted = vim.fn.split(content, [[\s*,\s*]])
  if #splitted == 0 then
    core.info('Canceled')
    return
  end
  if callback then
    callback(splitted)
  end
end

return M
