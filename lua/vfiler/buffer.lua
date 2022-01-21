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

function Buffer.new(name)
  local number = vim.fn.bufadd(name)
  -- Set a flag in the buffer variable to identify the vfiler.
  vim.fn.setbufvar(number, 'vfiler', 'vfiler')

  return setmetatable({
    number = number,
  }, Buffer)
end

function Buffer:delete()
  if self.number > 0 then
    vim.command('silent bwipeout ' .. self.number)
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

function Buffer:register_events(group, events, funcstr)
  if not events then
    return
  end
  vim.command('augroup ' .. group)
  for event, _ in pairs(events) do
    local au = ('autocmd %s <buffer> :lua %s(%d, "%s", "%s")'):format(
      event,
      funcstr,
      self.number,
      group,
      event
    )
    vim.command(au)
  end
  vim.command('augroup END')
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

function Buffer:unregister_events(group)
  vim.command('autocmd! ' .. group)
end

return Buffer
