local core = require('vfiler/libs/core')

local Popup = {}

function Popup.new()
  local Base = require('vfiler/views/base')
  local self = core.inherit(Popup, Base)
  self._popup_options = {}
  return self
end

function Popup:set_popup_option(key, value)
  self._popup_options[key] = value
end

function Popup:define_mappings(mappings, funcstr)
  local keypairs = {}
  for key, func in pairs(mappings) do
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
          funcstr, self._buffer.number, keypairs[key]
        )
        vim.fn.win_execute(winid, command)
      end
      return true
    end,
  })
  vim.fn.popup_setoptions(self.winid, options)

  -- NOTE: same mapping datas
  return mappings
end

function Popup:_get_popup_options(options)
  -- NOTE: 'filer' option are set during specific mapping
  local popup_options = vim.dict({
    border = vim.list({ 1, 1, 1, 1 }),
    col = options.col,
    cursorline = true,
    drag = false,
    line = options.row,
    mapping = false,
    minheight = options.height,
    minwidth = options.width,
    maxheight = options.height,
    maxwidth = options.width,
    pos = 'topleft',
    title = ' ' .. options.title .. ' ',
    wrap = false,
    zindex = 200,
  })
  for key, value in pairs(self._popup_options) do
    popup_options[key] = value
  end
  return popup_options
end

function Popup:_on_close(winid, buffer)
  if winid <= 0 then
    return
  end
  -- NOTE: If you do not run it from the calling window, you will get an error
  vim.fn.win_execute(self.src_winid, ('call popup_close(%d)'):format(winid))
end

function Popup:_on_open(buffer, options)
  local popup_options = self:_get_popup_options(options)
  local winid = vim.fn.popup_create(buffer.number, popup_options)

  -- set colors
  vim.fn.setwinvar(winid, '&wincolor', 'Normal')
  return winid
end

function Popup:_on_update(winid, buffer, options)
  if buffer.number ~= vim.fn.winbufnr(winid) then
    self:close()
    return self:_on_open(buffer, options)
  end
  local popup_options = self:_get_popup_options(options)
  vim.fn.popup_move(winid, popup_options)
  vim.fn.popup_setoptions(winid, popup_options)
  return winid
end

return Popup
