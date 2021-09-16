local vim = require 'vfiler/vim'
local core = require 'vfiler/core'

local M = {}

local BUFNAME_PREFIX = 'vfiler'
local BUFNAME_SEPARATOR = '-'
local BUFNUMBER_SEPARATOR = ':'
local DEAFULT_OPTIONS = {
  open_type = '',
  local_options = {},
}

-- Buffer management table
local buffer_table = {
  tabpages = {},

  add = function(self, object)
    local tabpagenr = vim.fn.tabpagenr()
    local buffers = self.tabpages[tabpagenr]
    if not buffers then
      buffers[object.number] = object
    end
    self.tabpages[tabpagenr] = buffers
  end,

  delete = function(self, object)
    self.tabpages[vim.fn.tabpagenr()][object.number] = nil
  end
}

local function create_name(basename)
  local bufname = BUFNAME_PREFIX
  if basename:len() > 0 then
    bufname = bufname .. BUFNAME_SEPARATOR .. basename
  end

  local tabpages = buffer_table.tabpages[vim.fn.tabpagenr()]

  local bufname_pattern = core.escape_pettern(bufname)

  local max_number = -1
  for t, _ in ipairs(buffers) do
    if name:match('^' .. bufname_pattern) then
      local number = name:match(BUFNUMBER_SEPARATOR .. '(%d+)$')
      if number then
        max_number = math.max(max_number, tonumber(number))
      else
        max_number = 0
      end
    end
  end

  if max_number >= 0 then
    bufname = bufname .. BUFNUMBER_SEPARATOR .. tostring(max_number + 1)
  end
  return bufname
end

local function create_object(name, number)
  local object = {
    name = name,
    number = number,
  }
  buffer_table.add(object)
  return object
end

function M.create(name, ...)
  local options = ... or DEAFULT_OPTIONS
  local bufname = create_name(name)

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

  return create_object(bufname, vim.fn.bufnr('%'))
end

-- Buffer object methods
local function delete(object)
  buffer_table.delete(object)
end

return M
