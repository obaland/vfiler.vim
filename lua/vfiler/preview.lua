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
      relativenumber = false,
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

  -- NOTE: Border correction is required between Neovim's floating window and
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
  self.opened = false
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

  local warning_syntax = 'vfilerPreviewWarning'
  local win_commands = {
    'filetype detect',
    core.syntax.clear_command({ warning_syntax }),
  }

  -- read file
  local lines = vim.to_vimlist({})
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

  local winid = self._view:open(buffer, options)
  vim.win_executes(winid, win_commands)

  -- return the current window
  core.window.move(self._winid)
  self.opened = true
end

function Preview:close()
  if self.opened then
    self._view:close()
  end
  self.opened = false
end

return Preview
