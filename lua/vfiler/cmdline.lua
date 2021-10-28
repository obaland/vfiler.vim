local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

M.choice = {
  Yes = 1,
  No = 2,
  Cancel = 3,
}

function M.confirm(prompt, choices, default)
  local list = {}
  for _, cvalue in ipairs(choices) do
    for key, value in pairs(M.choice) do
      if cvalue == value then
        table.insert(list, '&' .. key)
        break
      end
    end
  end
  local choice = vim.fn.confirm(prompt, table.concat(list, '\n'), default)
  if choice == 0 then
    return M.choice.Cancel
  end
  return list[choice]
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
