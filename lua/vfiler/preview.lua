local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Buffer = require('vfiler/buffer')

local Preview = {}
Preview.__index = Preview

local function new_view(options)
  local supported_layouts = {
    left = true,
    right = true,
    top = true,
    bottom = true,
    floating = true,
  }
  if not supported_layouts[options.layout] then
    core.message.error(
      'The "%s" layout is not supported in the preview window.',
      options.layout
    )
    return nil
  end

  local voptions = {
    layout = options.layout,
    width = options.width,
    height = options.height,
    winoptions = {
      number = true,
      cursorline = false,
    },
  }
  local view
  if options.layout == 'floating' then
    if core.is_nvim then
      view = require('vfiler/views/floating').new()
      view:set_config('focusable', false)
      view:set_config('zindex', 100)
    else
      view = require('vfiler/views/popup').new()
      view:set_popup_option('cursorline', false)
      view:set_popup_option('scrollbar', false)
      view:set_popup_option('zindex', 100)
    end
  else
    view = require('vfiler/views/window').new()
  end
  return view, voptions
end

local function get_floating_options(winid, default)
  local options = core.table.copy(default)
  local width = vim.get_global_option('columns')
  local height = vim.get_global_option('lines')
  local center = math.floor(width / 2)

  local screen_pos = vim.fn.win_screenpos(winid)
  local wincol = screen_pos[2]

  -- horizontal
  if wincol <= center then
    options.col = center + 1
  else
    options.col = 2
  end

  if options.width <= 0 then
    options.width = math.floor(width / 2) - 4
  end

  -- vertical
  if options.height <= 0 then
    options.height = math.floor(height * 0.8)
  end
  options.row = math.floor((height - options.height) / 2) - 1

  -- Note:
  -- Border correction is required between Neovim's floating window and
  -- Vim's pop-up window.

  if core.is_nvim then
    options.col = options.col - 1
    options.row = options.row - 1
  end

  return options
end

function Preview.new(options)
  local view, voptions = new_view(options)
  return setmetatable({
    _view = view,
    _options = voptions,
    _winid = vim.fn.win_getid(),
    opened = false,
    line = 0,
    isfloating = voptions.layout == 'floating',
  }, Preview)
end

function Preview:open(path)
  -- create buffer
  local bufname = 'vfiler-preview:' .. path
  local buffer = Buffer.new(bufname)

  -- NOTE:
  -- In the case of vim, avoid the problem that the top row of the window
  -- is changed arbitrarily.
  local saved_view = vim.fn.winsaveview()
  buffer:set_options({
    bufhidden = 'wipe',
    modifiable = false,
    modified = false,
    readonly = true,
    undofile = false,
    undolevels = 0,
  })
  vim.fn.winrestview(saved_view)

  local options
  if self._options.layout == 'floating' then
    options = get_floating_options(self._winid, self._options)
  else
    options = self._options
  end

  -- set title string
  local prefix = 'Preview - '
  local filename = core.path.name(path)
  local title
  if options.layout == 'floating' then
    local title_width = options.width - #prefix
    title = core.string.truncate(
      filename,
      title_width,
      '..',
      math.floor(title_width / 2)
    )
  else
    title = filename
  end
  options.title = prefix .. title

  local winid = self._view:open(buffer, options)
  vim.fn.win_execute(winid, 'filetype detect')

  local warning_syntax = 'vfilerPreviewWarning'
  vim.fn.win_execute(winid, core.syntax.clear_command({ warning_syntax }))

  -- read file
  local file = io.open(path, 'r')
  if file then
    local lines = vim.to_vimlist({})
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
    self._view:draw(lines)
  else
    -- draw warning message
    vim.win_executes(winid, {
      core.syntax.match_command(warning_syntax, [[\%1l.*]]),
      core.highlight.link_command(warning_syntax, 'WarningMsg'),
    })
    local message = ('"%s" could not be opened.'):format(filename)
    self._view:draw(vim.to_vimlist({ message }))
  end

  -- return the current window
  vim.fn.win_gotoid(self._winid)
  self.opened = true
end

function Preview:close()
  if self.opened then
    self._view:close()
  end
  self.opened = false
end

return Preview
