local M = {}

local function round(v)
  return math.floor(v + 0.5)
end

local function generate_string_value(t)
  local words = vim.deepcopy(t.words)
  local word_list = {}
  local num_words = round(math.random(t.min, #words))
  for _ = 1, num_words do
    local pos = round(math.random(1, #words))
    table.insert(word_list, words[pos])
    table.remove(words, pos)
  end
  return table.concat(word_list, t.sep)
end

local function generate_value(t)
  local value
  if type(t) == 'table' then
    if t.value then
      value = t.value
    elseif t.values then
      value = t.values[round(math.random(1, #t.values))]
    elseif t.int then
      value = round(math.random(t.int.min, t.int.max))
    elseif t.string then
      value = generate_string_value(t.string)
    else
      error('Not supported type')
    end
  elseif t == 'boolean' then
    value = math.random() >= 0.5
  else
    error('Not supported type.')
  end
  return value
end

local function generate_values(options, params)
  for key, t in pairs(params) do
    if type(t) == 'table' and t.nest then
      if not options[key] then
        options[key] = {}
      end
      generate_values(options[key], t.nest)
    else
      options[key] = generate_value(t)
    end
  end
end

local function convert_command_options(cmdopts, options, parent_key)
  for key, value in pairs(options) do
    local option = key:gsub('_', '-')
    if parent_key then
      option = parent_key .. '-' .. option
    end
    if type(value) == 'boolean' then
      option = value and option or 'no-' .. option
    elseif type(value) == 'number' then
      option = option .. '=' .. value
    elseif type(value) == 'string' then
      if #value > 0 then
        option = ('%s="%s"'):format(option, value)
      else
        option = nil
      end
    elseif type(value) == 'table' then
      convert_command_options(cmdopts, value, option)
      option = nil
    else
      error('Not supported type.')
    end

    if option then
      table.insert(cmdopts, '-' .. option)
    end
  end
end

function M.convert_command_options(options)
  local cmdopts = {}
  convert_command_options(cmdopts, options)
  return table.concat(cmdopts, ' ')
end

function M.generate_values(params)
  math.randomseed(math.floor(os.clock() * 1000))
  local options = {}
  generate_values(options, params)
  return options
end

function M.randomseed()
  math.randomseed(math.floor(os.clock() * 1000))
end

function M.feedkey(key, mode)
  mode = mode or ''
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(key, true, true, true),
    mode,
    true
  )
end

M.int = {}

function M.int.random(min, max)
  return round(math.random(min, max) + 0.5)
end

M.vfiler = {}

function M.vfiler.generate_options()
  local option_params = {
    auto_cd = 'boolean',
    auto_resize = 'boolean',
    columns = {
      string = {
        -- stylua: ignore
        words = {
          'indent',
          'icon',
          'name',
          'mode',
          'size',
          'time',
          'space',
          'git',
          'type',
        },
        min = 1,
        sep = ',',
      },
    },
    header = 'boolean',
    keep = 'boolean',
    listed = 'boolean',
    name = { values = { '', 'f-o-o', 'b-a-r' } },
    session = { values = { 'none', 'buffer', 'share' } },
    show_hidden_files = 'boolean',
    sort = { values = { 'name', 'extension', 'time', 'size' } },
    layout = {
      values = { 'none', 'right', 'left', 'top', 'bottom', 'tab' },
    },
    width = { int = { min = 10, max = 80 } },
    height = { int = { min = 10, max = 80 } },
    new = 'boolean',
    quit = 'boolean',
    border = {
      values = { 'none', 'single', 'double', 'rounded', 'shadow' },
    },
    col = { int = { min = 1, max = 30 } },
    row = { int = { min = 1, max = 30 } },
    blend = { int = { min = 10, max = 100 } },
    zindex = { int = { min = 100, max = 300 } },
    git = {
      nest = {
        enabled = 'boolean',
        ignored = 'boolean',
        untracked = 'boolean',
      },
    },
    preview = {
      nest = {
        layout = {
          values = { 'floating', 'right', 'left', 'top', 'bottom' },
        },
        width = { int = { min = 10, max = 80 } },
        height = { int = { min = 10, max = 80 } },
      },
    },
  }
  M.randomseed()
  return M.generate_values(option_params)
end

function M.vfiler.start(configs)
  require('vfiler').start('', configs)
  local filer = require('vfiler/vfiler').get(vim.fn.bufnr())
  return filer, filer._context, filer._view
end

function M.vfiler.start_command(args)
  require('vfiler').start_command(args)
  local filer = require('vfiler/vfiler').get(vim.fn.bufnr())
  assert(filer ~= nil)
  return filer, filer._context, filer._view
end

function M.vfiler.desc(name, filer)
  return ('%s root:%s'):format(name, filer._context.root.path)
end

return M
