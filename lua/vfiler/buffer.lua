local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local function escape_key(key)
  local capture = key:match('^<(.+)>$')
  if capture then
    key = '[' .. capture .. ']'
  end
  return key
end

local Buffer = {}
Buffer.__index = Buffer

function Buffer.is_vfiler_buffer(bufnr)
  return vim.fn.getbufvar(bufnr, 'vfiler') == 'vfiler'
end

function Buffer.new(name)
  local number = vim.fn.bufadd(name)
  if vim.fn.bufloaded(number) ~= 1 then
    -- NOTE: In the case of vim, an extra message is visible, so execute
    -- it with "silent".
    vim.fn.execute(('noautocmd call bufload(%d)'):format(number), 'silent')
  end

  -- Set a flag in the buffer variable to identify the vfiler.
  vim.fn.setbufvar(number, 'vfiler', 'vfiler')
  return setmetatable({
    number = number,
  }, Buffer)
end

function Buffer:delete()
  if vim.fn.bufexists(self.number) == 1 then
    vim.fn.execute(self.number .. 'bdelete!', 'silent')
  end
  self.number = -1
end

function Buffer:name()
  if self.number <= 0 then
    return ''
  end
  return vim.fn.bufname(self.number)
end

function Buffer:wipeout()
  if vim.fn.bufexists(self.number) == 1 then
    vim.fn.execute(self.number .. 'bwipeout!', 'silent')
  end
  self.number = -1
end

function Buffer:define_mappings(mappings, funcstr)
  if not mappings then
    return {}
  end

  local options = {
    noremap = true,
    nowait = true,
    silent = true,
  }

  local keymaps = {}
  for key, func in pairs(mappings) do
    local escaped = escape_key(key)
    local rhs = ([[:lua %s(%d, '%s')<CR>]]):format(
      funcstr,
      self.number,
      vim.fn.escape(escaped, '\\')
    )
    keymaps[escaped] = func
    vim.set_buf_keymap(self.number, 'n', key, rhs, options)
  end
  return keymaps
end

function Buffer:get_option(option)
  return vim.get_buf_option(self.number, option)
end

function Buffer:set_line(lnum, line)
  vim.fn.setbufline(self.number, lnum, line)
end

function Buffer:set_lines(lines)
  vim.fn.setbufline(self.number, 1, lines)
  vim.fn.deletebufline(self.number, #lines + 1, '$')
end

function Buffer:set_option(option, value)
  assert(self.number >= 0)
  vim.set_buf_option(self.number, option, value)
end

function Buffer:set_options(options)
  assert(self.number >= 0)
  vim.set_buf_options(self.number, options)
end

function Buffer:undefine_mappings(mappings)
  for key, _ in pairs(mappings) do
    vim.del_buf_keymap(self.number, 'n', key)
  end
end

return Buffer
