local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Buffer = {}
Buffer.__index = Buffer

local function create(name)
  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. name)
  vim.set_buf_option('swapfile', swapfile)

  -- Set buffer local options
  vim.set_buf_options {
    bufhidden = 'hide',
    buflisted = false,
    buftype = 'nofile',
    filetype = 'vfiler',
    modifiable = false,
    modified = false,
    readonly = false,
    swapfile = false,
  }

  -- Set window local options
  if vim.fn.exists('&colorcolumn') == 1 then
    vim.set_win_option('colorcolumn', '')
  end
  if vim.fn.has('conceal') == 1 then
    if vim.get_win_option_value('conceallevel') < 2 then
      vim.set_win_option('conceallevel', 2)
    end
    vim.set_win_option('concealcursor', 'nvc')
  end

  vim.set_win_options {
    foldcolumn = '0',
    foldenable = false,
    list = false,
    number = false,
    spell = false,
    wrap = false,
  }
  return vim.fn.bufnr()
end

function Buffer.new(bufname)
  local bufnr = create(bufname)
  return setmetatable({
      name = bufname,
      number = bufnr,
    }, Buffer)
end

function Buffer:delete()
  vim.command('silent bwipeout ' .. self.number)
end

function Buffer:duplicate()
  return Buffer.new(self.context.configs)
end

function Buffer:link(buffer)
  self.context.link_bufnr = buffer.bufnr
  buffer.context.link_bufnr = self.bufnr
end

function Buffer:open(...)
  local winnr = vim.fn.bufwinnr(self.number)
  if winnr > 0 then
    core.move_window(winnr)
  else
    local type = ...
    if type then
      -- open window
      core.open_window(type)
    end
    vim.command('silent buffer ' .. self.number)
  end
end

return Buffer
