local config = require 'vfiler/extensions/config'
local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Extension = {}
Extension.__index = Extension

local function calculate_size(winvalue, bufvalue, value)
  if value == 'auto' then
    local max = winvalue / 2
    return math.min(bufvalue + 1, max)
  end

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

function Extension.new(name, ...)
  local configs = ... or config.configs
  if not configs.layout then
    core.error('There are no layout option.')
    return nil
  end

  return setmetatable({
      configs = core.deepcopy(configs),
      name = name,
      number = 0,
    }, Extension)
end

function Extension:run(lines)
  -- split command
  vim.command(self:_get_wincommand())

  local bufname = 'vfiler/' .. self.name

  -- Save swapfile option
  local swapfile = vim.get_buf_option_boolean('swapfile')
  vim.set_buf_option('swapfile', false)
  vim.command('silent edit ' .. bufname)
  vim.set_buf_option('swapfile', swapfile)
  self.number = vim.fn.bufnr()

  self:_on_set_buf_option()
  self:_on_set_win_option()
  self:_on_mapping()

  -- draw line texts and syntax
  local num_lines, bufwidth = self:_on_draw(lines)

  -- resize window
  local winsize = self:_get_winsize(num_lines, bufwidth)
  if winsize.width > 0 then
    core.resize_window_width(winsize.width)
  end
  if winsize.height > 0 then
    core.resize_window_height(winsize.height)
  end
end

function Extension:quit()
  if self.number > 0 then
    vim.command('silent bwipeout ' .. self.number)
  end
end

function Extension:_get_wincommand()
  local layout = self.configs.layout
  local command = ''
  if layout['top'] then
    command = 'silent! aboveleft split'
  elseif layout['bottom'] then
    command = 'silent! belowright split'
  elseif layout['left'] then
    command = 'silent! aboveleft vertical split'
  elseif layout['right'] then
    command = 'silent! belowright vertical split'
  else
    core.error('Unsupported option.')
    return nil
  end
  return command
end

function Extension:_get_winsize(num_lines, bufwidth)
  local layout = self.configs.layout
  local winsize = {
    width = 0,
    height = 0,
  }
  if layout['top'] then
    winsize.height = calculate_size(
      vim.fn.winheight(0), num_lines, layout['top']
    )
  elseif layout['bottom'] then
    winsize.height = calculate_size(
      vim.fn.winheight(0), num_lines, layout['bottom']
    )
  elseif layout['left'] then
    winsize.width = calculate_size(
      vim.fn.winwidth(0), bufwidth, layout['left']
    )
  elseif layout['right'] then
    winsize.width = calculate_size(
      vim.fn.winwidth(0), bufwidth, layout['right']
    )
  else
    core.error('Unsupported option.')
    return nil
  end
  return winsize
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

function Extension:_on_draw(lines)
end

return Extension
