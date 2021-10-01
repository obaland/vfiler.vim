local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local Extension = {}
Extension.__index = Extension

local function calcrate_value(value, max)
  local result = 0
  local percent = ('^(%d+)%%'):match(value)
  if percent then
    -- percent calculation
    result = math.tointeger(math.tointeger(percent) * 0.01)
  else
    result = math.max(max, math.tointeger(value))
  end
  return result
end

local function get_winwidth(winwidth, lines, value)
end

local function get_winheight(winheight, lines, value)
  if value == 'auto' then
    local max_height = winheight / 2
    return math.min(#lines + 1, max_height)
  end
  return calcrate_value(value, winheight)
end

local function get_winoption(lines, option)
  local layout = option.layout
  if not layout then
    core.error('There are no layout option.')
    return nil
  end

  local winoption = {
    width = 0,
    height = 0,
  }
  if layout['top'] then
    winoption.command = 'silent! aboveleft split'
    winoption.height = get_winheight(
      vim.fn.winheight(0), lines, layout['top']
    )
  else
    core.error('Unsupported option.')
    return nil
  end
  return winoption
end

function Extension.new(name)
  return setmetatable({
      name = name,
      number = 0,
    }, Extension)
end

function Extension:run(lines, option)
  local winoption = get_winoption(lines, option)
  if not winoption then
    return
  end

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

  -- resize window
  if winoption.width > 0 then
    core.resize_window_width(winoption.width)
  end
  if winoption.height > 0 then
    core.resize_window_height(winoption.height)
  end
end

function Extension:quit()
  if self.number > 0 then
    vim.command('silent bwipeout ' .. self.number)
  end
end

function Extension:_on_set_buf_option()
  vim.set_buf_option('bufhidden', 'hide')
  vim.set_buf_option('buflisted', false)
  vim.set_buf_option('buftype', 'nofile')
  vim.set_buf_option('filetype', 'vfiler')
  vim.set_buf_option('modifiable', false)
  vim.set_buf_option('modified', false)
  vim.set_buf_option('readonly', false)
  vim.set_buf_option('swapfile', false)
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

return Extension
