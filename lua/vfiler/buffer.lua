local vim = require 'vfiler/vim'
local core = require 'vfiler/core'

local BUFNAME_PREFIX = 'vfiler'
local BUFNAME_SEPARATOR = '-'
local BUFNUMBER_SEPARATOR = ':'
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

local function generate_name(basename)
  local bufname = BUFNAME_PREFIX
  if basename:len() > 0 then
    bufname = bufname .. BUFNAME_SEPARATOR .. basename
  end

  local max_number = -1
  for _, buffer in pairs(buffers.table) do
    if basename == buffer.name then
      max_number = math.max(buffer._local_number, max_number)
    end
  end

  local number = 0
  if max_number >= 0 then
    number = max_number + 1
    bufname = bufname .. BUFNUMBER_SEPARATOR .. tostring(number)
  end
  return bufname, basename, number
end

function Buffer.open(name, ...)
  local tabpagenr = vim.fn.tabpagenr()
  for _, buffer in pairs(buffers.table) do
    if tabpagenr == buffer._tabpagenr and name == buffer.name then
      local winnr = vim.fn.bufwinnr(buffer.bufnr)
      if winnr > 0 then
        -- Move to opened window
        vim.command(winnr .. 'wincmd w')
      else
        vim.command('silent buffer ' .. buffer.bufnr)
      end
      return buffer
    end
  end
  return nil
end

function Buffer.new(name, ...)
  local options = ... or DEAFULT_OPTIONS
  local bufname, basename, local_number = generate_name(name)

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
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

  local object = setmetatable({
      name = name,
      number = vim.fn.bufnr(),
      _local_number = local_number,
      _tabpagenr = vim.fn.tabpagenr(),
    }, Buffer)
  buffers:add(object)
  return object
end

function Buffer:delete()
  buffers:delete(self)
end

return Buffer
