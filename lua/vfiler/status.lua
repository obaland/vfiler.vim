local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

local status_configs = {
  components = {
    { 'root' },
    { 'numitems', 'itemname' },
  },
  separator = '|',
  subseparator = '>',

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
      return item.name .. (item.is_directory and '/' or '')
    end,
  },
}

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
    '%#vfilerStatusLineSection1#',
    padding,
    key,
    padding,
    '%#vfilerStatusLine#',
  }
  return table.concat(status, '')
end

--- Status for statusline
---@param context table
---@param view table
function M.status(context, view)
  local status_parts = {}
  local components = status_configs.components
  local functions = status_configs.component_functions

  local separator
  if #status_configs.separator > 0 then
    separator = ' ' .. status_configs.separator .. ' '
  else
    separator = ' '
  end

  local subseparator
  if #status_configs.subseparator > 0 then
    subseparator = ' ' .. status_configs.subseparator .. ' '
  else
    subseparator = ' '
  end

  for _, component in ipairs(components) do
    local parts = {}
    for _, subcomponent in ipairs(component) do
      local func = functions[subcomponent]
      if func then
        local part = func(context, view)
        if #part > 0 then
          table.insert(parts, part)
        end
      end
    end
    table.insert(status_parts, table.concat(parts, subseparator))
  end
  return table.concat(status_parts, separator)
end

--- Setup status configs
---@param configs table
function M.setup(configs)
  core.table.merge(status_configs, configs)
  return status_configs
end

return M
