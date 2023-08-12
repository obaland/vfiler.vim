local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

M.choice = {
  YES = '&Yes',
  NO = '&No',
  CANCEL = '&Cancel',
  RENAME = '&Rename',
}

function M.clear_prompt()
  -- Clear the message show on the command line.
  vim.fn.feedkeys(':', 'nx')
end

function M.confirm(prompt, choices, default)
  M.clear_prompt()
  prompt = ('[vfiler] %s'):format(prompt)
  local choice = vim.fn.confirm(prompt, table.concat(choices, '\n'), default)
  M.clear_prompt()
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
  M.clear_prompt()

  local char = nil
  if (32 <= code) and (code <= 126) then
    char = string.char(code)
  elseif code == 27 then
    char = '<ESC>'
  end
  return char
end

function M.input(prompt, ...)
  local args = ... and { ... } or {}
  local text = args[1] or ''
  local completion = args[2]

  prompt = ('[vfiler] %s: '):format(prompt)

  local content
  if completion then
    content = vim.fn.input(prompt, text, completion)
  else
    content = vim.fn.input(prompt, text)
  end
  M.clear_prompt()
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
    { M.choice.YES, M.choice.NO },
    1
  )
end

function M.util.confirm_overwrite_or_rename(name)
  return M.confirm(
    ('"%s" already exists. Overwrite?'):format(name),
    { M.choice.YES, M.choice.NO, M.choice.RENAME },
    1
  )
end

return M
