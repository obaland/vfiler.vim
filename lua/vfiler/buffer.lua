local vim = require 'vfiler/vim'
local core = require 'vfiler/core'

local DEAFULT_OPTIONS = {
  open_type = '',
  local_options = {},
}

-- Buffer management table
local buffers = {
  table = {},

  add = function(self, buffer)
    self.table[buffer.number] = buffer
  end,

  delete = function(self, buffer)
    self.table[buffer.number] = nil
  end
}

local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(name, ...)
  local options = ... or DEAFULT_OPTIONS

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. name)
  vim.set_buf_option('swapfile', swapfile)

  -- Set buffer local options
  vim.set_buf_option('bufhidden', 'hide')
  vim.set_buf_option('buflisted', false)
  vim.set_buf_option('buftype', 'nofile')
  vim.set_buf_option('filetype', 'vfiler')
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('modified', false)
  vim.set_buf_option('readonly', false)
  vim.set_buf_option('swapfile', false)

  -- Set window local options
  if vim.fn.exists('&colorcolumn') == 1 then
    vim.set_win_option('colorcolumn', '')
  end
  vim.set_win_option('foldcolumn', '0')
  vim.set_win_option('foldenable', false)
  vim.set_win_option('list', false)
  vim.set_win_option('number', false)
  vim.set_win_option('spell', false)
  vim.set_win_option('wrap', false)

  return setmetatable({
      name = name,
      number = vim.fn.bufnr(),
      _tabpagenr = vim.fn.tabpagenr(),
    }, Buffer)
end

function Buffer:delete()
  buffers:delete(self)
end

function Buffer:open(name)
  local winnr = vim.fn.bufwinnr(self.number)
  if winnr > 0 then
    -- Move to opened window
    vim.command(winnr .. 'wincmd w')
  else
    vim.command('silent buffer ' .. self.number)
  end
end

return Buffer
