local api = vim.api
local core = require('vfiler/libs/core')

local Floating = {}

function Floating.new()
  local Window = require('vfiler/windows/window')
  local self = core.inherit(Floating, Window)
  self._winid = 0
  self._config = {}
  return self
end

function Floating:set_title(title)
  assert(self._winid > 0)
  local config, title_name = self:_get_title_config(title, self._config)
  if self._title then
    -- update
    api.nvim_win_set_config(self._title.winid, config)
    api.nvim_buf_set_lines(self._title.bufnr, 0, -1, true, { title_name })
    self._title.name = title
  else
    -- create
    config.noautocmd = true
    local bufnr = api.nvim_create_buf(false, true)
    local winid = api.nvim_open_win(bufnr, false, config)

    -- set options
    api.nvim_win_set_option(
      winid,
      'winhighlight',
      'Normal:vfilerFloatingWindowTitle'
    )
    api.nvim_win_set_option(winid, 'cursorline', false)
    api.nvim_win_set_option(winid, 'number', false)
    api.nvim_win_set_option(winid, 'relativenumber', false)
    api.nvim_win_set_option(winid, 'signcolumn', 'no')

    -- set title name
    api.nvim_buf_set_lines(bufnr, 0, -1, true, { title_name })

    self._title = {
      name = title,
      bufnr = bufnr,
      winid = winid,
    }
  end
end

function Floating:close()
  if self._winid > 0 then
    api.nvim_win_close(self._winid, true)
    self._winid = 0
  end
  if self._title then
    api.nvim_win_close(self._title.winid, true)
    self._title = nil
  end
end

function Floating:id()
  return self._winid
end

function Floating:type()
  return 'floating'
end

function Floating:_on_open(buffer, config)
  self._config = self:_to_win_config(config)
  self._config.noautocmd = true
  local enter = config.focusable ~= nil and config.focusable or true
  self._winid = api.nvim_open_win(buffer.number, enter, self._config)
  api.nvim_win_set_option(self._winid, 'winhighlight', 'Normal:Normal')
  return self._winid
end

function Floating:_on_update(winid, buffer, config)
  if buffer.number ~= api.nvim_win_get_buf(winid) then
    api.nvim_win_set_buf(winid, buffer.number)
  end
  self._config = self:_to_win_config(config)
  api.nvim_win_set_config(winid, self._config)
  if self._title then
    self:_update_title(self._config)
  end
  return winid
end

function Floating:_update_title(win_config)
  local config = self:_get_title_config(self._title.name, win_config)
  api.nvim_win_set_config(self._title.winid, config)
end

function Floating:_get_title_config(title, win_config)
  local title_name = ' ' .. title .. ' '
  local config = {
    col = win_config.col + 1,
    focusable = false,
    height = 1,
    relative = win_config.relative,
    row = win_config.row,
    zindex = win_config.zindex + 1,
    width = #title_name,
  }
  if config.relative == 'win' then
    config.win = self.src_winid
  end
  return config, title_name
end

function Floating:_to_win_config(config)
  local win_config = {
    border = config.border or 'rounded',
    col = config.col,
    focusable = true,
    height = config.height,
    relative = 'editor',
    row = config.row,
    width = config.width,
    zindex = config.zindex or 200,
  }
  if config.focusable ~= nil then
    win_config.focusable = config.focusable
  end
  return win_config
end

return Floating
