local vim = require 'vfiler/vim'

local Context = require 'vfiler/context'
local View = require 'vfiler/view'

local BUFNAME_PREFIX = 'vfiler'
local BUFNAME_SEPARATOR = '-'
local BUFNUMBER_SEPARATOR = ':'

local Buffer = {}
Buffer.__index = Buffer

-- Buffer resource management table
local buffer_resources = {}

local function create(name)
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
  if vim.fn.has('conceal') == 1 then
    if vim.get_win_option_value('conceallevel') < 2 then
      vim.set_win_option('conceallevel', 2)
    end
    vim.set_win_option('concealcursor', 'nvc')
  end
  vim.set_win_option('foldcolumn', '0')
  vim.set_win_option('foldenable', false)
  vim.set_win_option('list', false)
  vim.set_win_option('number', false)
  vim.set_win_option('spell', false)
  vim.set_win_option('wrap', false)
  return vim.fn.bufnr()
end

local function generate_name(name)
  local bufname = BUFNAME_PREFIX
  if name:len() > 0 then
    bufname = bufname .. BUFNAME_SEPARATOR .. name
  end

  local max_number = -1
  for _, source in pairs(buffer_resources) do
    if name == source.name then
      max_number = math.max(source.local_number, max_number)
    end
  end

  local number = 0
  if max_number >= 0 then
    number = max_number + 1
    bufname = bufname .. BUFNUMBER_SEPARATOR .. tostring(number)
  end
  return bufname, name, number
end

function Buffer.find(name)
  local tabpagenr = vim.fn.tabpagenr()
  for _, resource in pairs(buffer_resources) do
    local buffer = resource.buffer
    if tabpagenr == buffer._tabpagenr and name == buffer.name then
      return buffer
    end
  end
  return nil
end

function Buffer.get(bufnr)
  return buffer_resources[bufnr].buffer
end

function Buffer.new(configs)
  local bufname, name, local_number = generate_name(configs.name)
  local buffer = setmetatable({
      context = Context.new(configs),
      name = bufname,
      number = create(bufname),
      view = View.new(configs),
      _tabpagenr = vim.fn.tabpagenr(),
    }, Buffer)

  -- add buffer resource
  buffer_resources[buffer.number] = {
    buffer = buffer,
    name = name,
    local_number = local_number,
  }
  return buffer
end

function Buffer:delete()
  buffer_resources[self.number] = nil
end

function Buffer:open()
  local winnr = vim.fn.bufwinnr(self.number)
  if winnr > 0 then
    -- Move to opened window
    vim.command(winnr .. 'wincmd w')
  else
    vim.command('silent buffer ' .. self.number)
  end
end

return Buffer
