local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

local status_configs = {
  components = {
    { 'root' },
    { 'numitems', 'itemname' },
  },
  separator = ' | ',
  subseparator = ' > ',

  component_functions = {
    name = function(context, view)
      return vim.fn.expand('%')
    end,

    root = function(context, view)
      local root = vim.fn.fnamemodify(context.root.path, ':~'):gsub('\\', '/')
      return '[in] ' .. root
    end,

    numitems = function(context, view)
      local offset = context.options.header and 1 or 0
      local num_items = vim.fn.line('$') - offset
      local line = vim.fn.line('.') - offset

      local digit = 0
      local num = num_items
      while num > 0 do
        digit = digit + 1
        num = math.modf(num / 10)
      end
      return ('[%%%dd/%%%dd]'):format(digit, digit):format(line, num_items)
    end,

    itemname = function(context, view)
      local item = view:get_current()
      if not item then
        return ''
      end
      local name = item.name
      if item.type == 'directory' then
        name = name .. '/'
      end
      return name
    end,
  },

  component_highlights = {
    'vfilerStatusLineComponent1',
    'vfilerStatusLineComponent2',
  },
}

local function build_status_blocks(context, view)
  local components = status_configs.components
  local functions = status_configs.component_functions

  local status_blocks = {}
  for _, component in ipairs(components) do
    local blocks = {}
    for _, subcomponent in ipairs(component) do
      local func = functions[subcomponent]
      if func then
        local block = func(context, view)
        if #block > 0 then
          table.insert(blocks, block)
        end
      end
    end
    table.insert(status_blocks, blocks)
  end
  return status_blocks
end

--- Status line for choose window key display
---@param winwidth number
---@param key string
function M.choose_window_key(winwidth, key)
  local caption_width = winwidth / 4
  local padding = (' '):rep(math.ceil(caption_width / 2))
  local margin = (' '):rep(math.ceil((winwidth - caption_width) / 2))
  local status = {
    '%#vfilerStatusLine#',
    margin,
    '%#vfilerStatusLineSection#',
    padding,
    key,
    padding,
    '%#vfilerStatusLine#',
  }
  return table.concat(status, '')
end

--- Status string
---@param context table
---@param view table
function M.status(context, view)
  local status = {}
  for _, blocks in ipairs(build_status_blocks(context, view)) do
    table.insert(status, table.concat(blocks, status_configs.subseparator))
  end
  return table.concat(status, status_configs.separator)
end

--- Status string for statusline
---@param context table
---@param view table
function M.statusline(context, view)
  local status = {}
  local status_blocks = build_status_blocks(context, view)
  for i = 1, #status_blocks do
    local hl = status_configs.component_highlights[i]
    if not hl then
      hl = 'vfilerStatusLine'
    end
    local block = ('%%#%s#%s'):format(
      hl,
      table.concat(status_blocks[i], status_configs.subseparator)
    )
    table.insert(status, block)
  end
  return table.concat(status, status_configs.separator)
end

--- Setup status configs
---@param configs table
function M.setup(configs)
  core.table.merge(status_configs, configs)
  if #status_configs.separator > 0 then
    status_configs.separator = ' ' .. status_configs.separator .. ' '
  end
  if #status_configs.subseparator > 0 then
    status_configs.subseparator = ' ' .. status_configs.subseparator .. ' '
  end
  return status_configs
end

return M
