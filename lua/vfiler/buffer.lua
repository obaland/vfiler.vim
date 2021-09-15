local vim = require 'vfiler/vim'

local BUFNAME_PREFIX = 'vfiler:' -- Buffer name prefix string constant
local DEAFULT_OPTIONS = {
  open_type = '',
  local_options = {},
}


local M = {}

local function create_name(basename)
  return BUFNAME_PREFIX .. basename
end

function M.create(name, ...)
  local options = ... or DEAFULT_OPTIONS
  local bufname = create_name(name)

  -- Save swapfile option
  local swapfile = vim.g.swapfile
end

return M
