local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local extension_resources = {}

local Extension = {}
Extension.__index = Extension

local function calculate_value(winvalue, value)
  local result = 0
  local percent = value:match('^(%d+)%%$')
  if percent then
    -- percent calculation
    result = math.floor(winvalue * tonumber(percent) * 0.01 + 0.5)
  else
    result = math.max(winvalue, tonumber(value))
  end
  return result
end

local function calculate_width(texts, value)
  local winwidth = vim.fn.winwidth(0)
  if value == 'auto' then
    local max = winwidth / 2
    local bufwidth = 0
    for _, text in ipairs(texts) do
      local width = vim.fn.strwidth(text)
      if bufwidth < width then
        bufwidth = width
      end
    end
    return math.min(bufwidth + 1, max)
  end
  return calculate_value(winwidth, value)
end

local function calculate_height(texts, value)
  local winheight = vim.fn.winheight(0)
  if value == 'auto' then
    local max = winheight / 2
    return math.min(#texts + 1, max)
  end
  return calculate_value(winheight, value)
end

function Extension.new(name, context, items, ...)
  local configs = ... or config.configs
  local object = setmetatable({
      configs = core.deepcopy(configs),
      context = context,
      items = items,
      name = name,
    }, Extension)
  object.number = object:_create()

  -- add extension table
  extension_resources[object.number] = object
  return object
end

function Extension:delete()
  extension_resources[self.number] = nil
end

function Extension:quit()
  vim.command('silent bwipeout ' .. self.number)
end

function Extension:_create()
  local texts = self:_on_get_texts()
  local winoption = self:_get_winoption(texts)

  -- split command
  vim.command(winoption.command)

  local bufname = 'vfiler/' .. self.name

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
  vim.set_buf_option('swapfile', swapfile)

  self:_on_set_buf_option()
  self:_on_set_win_option()
  self:_on_mapping()

  -- resize window
  if winoption.width > 0 then
    core.resize_window_width(winoption.width)
  end
  if winoption.height > 0 then
    core.resize_window_height(winoption.height)
  end

  -- draw line texts and syntax
  self:_on_draw(texts, vim.fn.winwidth(0), vim.fn.winheight(0))

  return vim.fn.bufnr()
end

function Extension:_get_winoption(texts)
  local option = {
    width = 0, height = 0,
  }

  local layout = self.configs.layout
  if layout.top then
    option.command = 'silent! aboveleft split'
    option.height = calculate_height(texts, layout.top)
  elseif layout.bottom then
    option.command = 'silent! belowright split'
    option.height = calculate_height(texts, layout.bottom)
  elseif layout.left then
    option.command = 'silent! aboveleft vertical split'
    option.width = calculate_width(texts, layout.left)
  elseif layout.right then
    option.command = 'silent! belowright vertical split'
    option.width = calculate_width(texts, layout.right)
  else
    core.error('Unsupported option.')
    return nil
  end
  return option
end

function Extension:_on_set_buf_option()
end

function Extension:_on_set_win_option()
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
end

function Extension:_on_mapping()
end

function Extension:_on_get_texts()
end

function Extension:_on_draw(texts, winwidth, winheight)
end

return Extension
