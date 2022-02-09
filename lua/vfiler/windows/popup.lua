local core = require('vfiler/libs/core')

local Popup = {}

function Popup.new()
  local Window = require('vfiler/windows/window')
  local self = core.inherit(Popup, Window)
  self._src_winid = vim.fn.win_getid()
  self._winid = 0
  return self
end

function Popup:close()
  if self._winid <= 0 then
    return
  end
  -- NOTE: If you do not run it from the calling window, you will get an error
  vim.fn.win_execute(
    self._src_winid,
    ('call popup_close(%d)'):format(self._winid)
  )
  self._winid = 0
  self._bufnr = 0
end

function Popup:define_mappings(mappings, funcstr)
  local keypairs = {}
  for key, _ in pairs(mappings) do
    local code = key
    if core.string.is_keycode(key) then
      code = core.string.replace_keycode(key)
    end
    keypairs[code] = key
  end

  local options = vim.dict({
    filter = function(winid, key)
      if keypairs[key] then
        local command = (':lua %s(%d, "%s")'):format(
          funcstr,
          self._bufnr,
          keypairs[key]
        )
        vim.fn.win_execute(winid, command)
      end
      return true
    end,
  })
  vim.fn.popup_setoptions(self._winid, options)

  -- NOTE: same mapping datas
  return mappings
end

function Popup:id()
  return self._winid
end

function Popup:set_title(title)
  assert(self._winid > 0)
  vim.fn.popup_setoptions(
    self._winid,
    vim.dict({ title = ' ' .. title .. ' ' })
  )
end

function Popup:type()
  return 'popup'
end

function Popup:_to_popup_options(config)
  -- NOTE: 'filer' option are set during specific mapping
  local options = vim.dict({
    border = vim.list({ 1, 1, 1, 1 }),
    col = config.col,
    cursorline = true,
    drag = false,
    line = config.row,
    mapping = false,
    minheight = config.height,
    minwidth = config.width,
    maxheight = config.height,
    maxwidth = config.width,
    pos = 'topleft',
    scrollbar = true,
    wrap = false,
    zindex = config.zindex or 200,
  })
  if config.cursorline ~= nil then
    options.cursorline = config.cursorline
  end
  if config.scrollbar ~= nil then
    options.scrollbar = config.scrollbar
  end
  return options
end

function Popup:_on_open(buffer, config)
  local popup_options = self:_to_popup_options(config)
  self._winid = vim.fn.popup_create(buffer.number, popup_options)
  vim.fn.setwinvar(self._winid, '&wincolor', 'Normal')
  return self._winid
end

function Popup:_on_update(winid, buffer, config)
  if buffer.number ~= vim.fn.winbufnr(winid) then
    self:close()
    return self:_on_open(buffer, config)
  end
  local popup_options = self:_to_popup_options(config)
  vim.fn.popup_move(winid, popup_options)
  vim.fn.popup_setoptions(winid, popup_options)
  return winid
end

return Popup
