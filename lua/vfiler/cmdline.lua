local core = require('vfiler/core')
local vim = require('vfiler/vim')

local M = {}

M.choice = {
  YES = '&Yes',
  NO = '&No',
  CANCEL = '&Cancel',
}

function M.confirm(prompt, choices, default)
  vim.command('echon')
  prompt = ('[vfiler] %s'):format(prompt)
  local choice = vim.fn.confirm(prompt, table.concat(choices, '\n'), default)
  vim.command('redraw')
  if choice == 0 then
    return M.choice.Cancel
  end
  return choices[choice]
end

function M.getchar(prompt)
  prompt = ('[vfiler] %s: '):format(prompt)
  local commands = {
    'echohl Question',
    ('echon "%s"'):format(prompt),
    'echohl None',
  }
  vim.commands(commands)
  local code = vim.fn.getchar()
  vim.command('echo ""')

  local char = nil
  if (32 <= code) and (code <= 126) then
    char = string.char(code)
  elseif code == 27 then
    char = '<ESC>'
  end
  return char
end

function M.input(prompt, ...)
  local args = ... and {...} or {}
  local text = args[1] or ''
  local completion = args[2]

  prompt = ('[vfiler] %s: '):format(prompt)

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
    return
  end
  if callback then
    callback(core.list.unique(splitted))
  end
end

------------------------------------------------------------------------------
-- Utilities
------------------------------------------------------------------------------
M.util = {}

function M.util.confirm_overwrite(name)
  return M.confirm(
    ('"%s" already exists. Overwrite?'):format(name),
    {M.choice.YES, M.choice.NO}, 1
  )
end

return M
