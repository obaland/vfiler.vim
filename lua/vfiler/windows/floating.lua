local api = vim.api
local core = require('vfiler/libs/core')

local Buffer = require('vfiler/buffer')

local Floating = {}

function Floating._try_close(winid)
  if api.nvim_win_is_valid(winid) then
    api.nvim_win_close(winid, true)
  end
end

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
    local buffer = self._title.buffer
    core.try({
      function()
        buffer:set_option('modifiable', true)
        buffer:set_option('readonly', false)
        buffer:set_line(1, title_name)
      end,
      finally = function()
        buffer:set_option('modifiable', false)
        buffer:set_option('readonly', true)
      end,
    })
    self._title.name = title
  else
    -- create
    local buffer = Buffer.new('vfiler-title:' .. title)
    buffer:set_options({
      bufhidden = 'wipe',
      buflisted = false,
      buftype = 'nofile',
      swapfile = false,
    })

    config.noautocmd = true
    local winid = api.nvim_open_win(buffer.number, false, config)

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
    core.try({
      function()
        buffer:set_option('modifiable', true)
        buffer:set_option('readonly', false)
        buffer:set_line(1, title_name)
      end,
      finally = function()
        buffer:set_option('modifiable', false)
        buffer:set_option('readonly', true)
      end,
    })

    self._title = {
      name = title,
      buffer = buffer,
      winid = winid,
    }
  end
end

function Floating:close()
  local close = Floating._try_close
  if self._title then
    close(self._title.winid)
    self._title = nil
  end
  if self._winid > 0 then
    close(self._winid)
    self._winid = 0
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

  local autocmd = {
    'autocmd! QuitPre',
    ('<buffer=%d> ++once ++nested'):format(buffer.number),
    (':lua require("vfiler/windows/floating")._try_close(%d)'):format(
      self._winid
    ),
  }
  vim.cmd(table.concat(autocmd, ' '))

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
