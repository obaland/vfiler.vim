local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local Preview = {}
Preview.__index = Preview

local function new_window(options)
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

  local woptions = {
    layout = options.layout,
    width = options.width,
    height = options.height,
  }
  local window
  if options.layout == 'floating' then
    if core.is_nvim then
      window = require('vfiler/windows/floating').new()
      woptions.focusable = false
      woptions.zindex = 300
    else
      window = require('vfiler/windows/popup').new()
      woptions.cursorline = false
      woptions.scrollbar = false
      woptions.zindex = 300
    end
  else
    window = require('vfiler/windows/window').new()
  end
  return window, woptions
end

local function set_floating_size(winid, default)
  local options = core.table.copy(default)
  local width = vim.get_option('columns')
  local height = vim.get_option('lines')
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

  -- NOTE: Border correction is required between Neovim's floating window and
  -- Vim's pop-up window.

  if core.is_nvim then
    options.col = options.col - 1
    options.row = options.row - 1
  end
  return options
end

function Preview.new(options)
  local window, woptions = new_window(options)
  return setmetatable({
    _window = window,
    _options = woptions,
    _winid = vim.fn.win_getid(),
    opened = false,
    line = 0,
  }, Preview)
end

function Preview:open(path)
  local window = self._window
  local options
  if window:type() == 'window' then
    options = self._options
  else
    options = set_floating_size(self._winid, self._options)
  end

  local warning_syntax = 'vfilerPreviewWarning'
  local win_commands = {
    'filetype detect',
    core.syntax.clear_command({ warning_syntax }),
  }

  -- read file
  local filename = core.path.name(path)
  local lines = vim.list({})
  local file = io.open(path, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  else
    -- warning message & syntax
    table.insert(
      win_commands,
      core.syntax.match_command(warning_syntax, [[\%1l.*]])
    )
    table.insert(
      win_commands,
      core.highlight.link_command(warning_syntax, 'WarningMsg')
    )
    local message = ('"%s" could not be opened.'):format(filename)
    table.insert(lines, message)
  end

  local Buffer = require('vfiler/buffer')

  -- NOTE: In the case of vim, avoid the problem that the top row of
  -- the window is changed arbitrarily.
  local saved_view = vim.fn.winsaveview()
  local bufname = 'vfiler-preview:' .. path
  local buffer = Buffer.new(bufname)
  vim.fn.winrestview(saved_view)

  core.try({
    function()
      buffer:set_options({
        bufhidden = 'wipe',
        buflisted = false,
        buftype = 'nofile',
        swapfile = false,
        undofile = false,
        undolevels = 0,
      })
      buffer:set_lines(lines)
    end,
    finally = function()
      buffer:set_options({
        modifiable = false,
        modified = false,
        readonly = true,
      })
    end,
  })

  if options.layout ~= 'floating' then
    if self.opened then
      core.window.move(window:id())
    else
      core.window.open(options.layout)
    end
  end
  local winid = window:open(buffer, options)
  -- NOTE: For vim, don't explicitly set the "signcolumn" option as the
  -- screen may flicker.
  if core.is_nvim then
    window:set_option('signcolumn', 'no')
  end
  window:set_option('cursorline', false)
  vim.win_executes(winid, win_commands, 'silent')

  -- set title string
  local prefix = 'Preview - '
  local title
  if window:type() == 'floating' then
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
  window:set_title(prefix .. title)

  -- return the current window
  core.window.move(self._winid)
  self.opened = true
end

function Preview:close()
  if self.opened then
    self._window:close()
  end
  self.opened = false
end

return Preview
