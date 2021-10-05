local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Window = {}
Window.__index = Window

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

function Window.new(configs)
  return setmetatable({
      configs = core.deepcopy(configs),
      height = 0,
      width = 0,
      bufnr = 0,
      bufoptions = {},
      winoptions = {
        colorcolumn = '',
        conceallevel =  2,
        concealcursor = 'nvc',
        foldcolumn = '0',
        foldenable = false,
        list = false,
        number = false,
        spell = false,
        wrap = false,
      },
    }, Window)
end

function Window:close()
  vim.command('silent bwipeout ' .. self.bufnr)
end

function Window:open(name, texts)
  local layout = self:_get_layout_option(texts)

  -- split command
  vim.command(layout.command)

  local bufname = 'vfiler/' .. name

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
  vim.set_buf_option('swapfile', swapfile)

  -- resize window
  if layout.width > 0 then
    self.width = layout.width
    core.resize_window_width(layout.width)
  else
    self.width = vim.fn.winwidth(0)
  end
  if layout.height > 0 then
    self.height = layout.height
    core.resize_window_height(layout.height)
  else
    self.height = vim.fn.winheight(0)
  end

  self:_set_options()
  self.bufnr = vim.fn.bufnr()
  return self.bufnr
end

function Window:draw(texts, ...)
  vim.command('silent %delete _')

  for i, text in ipairs(texts) do
    vim.fn.setline(i, text)
  end

  -- set statusline
  if ... then
    vim.set_win_option('statusline', ...)
  end
end

function Window:set_buf_options(options)
  core.merge_table(self.bufoptions, options)
end

function Window:set_win_options(options)
  core.merge_table(self.winoptions, options)
end

function Window:_get_layout_option(texts)
  local option = {
    width = 0, height = 0,
  }

  local layout = self.configs
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

function Window:_set_options()
  -- set buffer options
  if self.bufoptions then
    for key, value in pairs(self.bufoptions) do
      vim.set_buf_option(key, value)
    end
  end

  -- set window options
  if self.winoptions then
    for key, value in pairs(self.winoptions) do
      vim.set_win_option(key, value)
    end
  end
end

return Window
