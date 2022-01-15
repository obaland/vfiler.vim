local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Popup = {}

function Popup.new()
  local Window = require('vfiler/views/window')
  return core.inherit(Popup, Window)
end

function Popup:close()
  if self.winid > 0 then
    -- Note: If you do not run it from the calling window, you will get an error
    vim.fn.win_execute(
      self.source_winid,
      ('call popup_close(%d)'):format(self.winid)
    )
  end
end

function Popup:define_mapping(mappings, funcstr)
  local keys = {}
  for key, _ in pairs(mappings) do
    table.insert(keys, key)
  end
  vim.fn['vfiler#popup#map'](
    self.winid,
    self.bufnr,
    vim.to_vimlist(keys),
    funcstr
  )
  -- Note: same mapping datas
  return core.table.copy(mappings)
end

function Popup:draw(lines)
  -- Nothing to do
end

function Popup:_on_open(lines, options)
  local popup_options = {
    border = vim.to_vimlist({ 1, 1, 1, 1 }),
    cursorline = true,
    drag = false,
    filter = 'vfiler#popup#filter',
    mapping = false,
    minheight = options.minheight,
    minwidth = options.minwidth,
    title = ' ' .. options.name .. ' ',
    wrap = false,
    zindex = 200,
    width = options.width,
  }
  if options.relative then
    popup_options.pos = 'topleft'
    local wwidth = vim.fn.winwidth(self.source_winid)
    local wheight = vim.fn.winheight(self.source_winid)
    local screen_pos = vim.fn.win_screenpos(self.source_winid)
    local y = screen_pos[1]
    local x = screen_pos[2]
    popup_options.line = y
      + math.floor(
        wheight - ((options.height / 2) + (wheight / 2))
      )
      - 1
    popup_options.col = x
      + math.floor(
        wwidth - ((options.width / 2) + (wwidth / 2))
      )
      - 1
  else
    popup_options.pos = 'center'
  end

  local winid = vim.fn.popup_create(
    vim.to_vimlist(lines),
    vim.to_vimdict(popup_options)
  )

  -- set wincolor option
  vim.set_win_option(winid, 'wincolor', 'Normal')

  return winid
end

return Popup
