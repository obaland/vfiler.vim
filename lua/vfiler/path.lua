local core = require 'vfiler/core'
local vim = require 'vfiler/vim'

local M = {}

function M.exists(path)
  return vim.fn.filereadable(path) == 1
end

function M.isdirectory(path)
  return vim.fn.isdirectory(path) == 1
end

function M.join(path, name)
  if path:sub(#path, #path) ~= '/' then
    path = path .. '/'
  end
  if name:sub(1, 1) == '/' then
    name = name:sub(2)
  end
  return path .. name
end

function M.normalize(path)
  if path == '/' then
    return '/'
  end

  local result = vim.fn.fnamemodify(path, ':p')
  if core.is_windows then
    result = result:gsub('\\', '/')
  end
  return result
end

return M
