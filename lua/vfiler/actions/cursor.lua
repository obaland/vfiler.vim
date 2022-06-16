local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

function M.loop_cursor_down(vfiler, context, view)
  local lnum = vim.fn.line('.') + 1
  local num_end = view:num_lines()
  if lnum > num_end then
    core.cursor.move(view:top_lnum())
    -- Correspondence to show the header line
    -- when moving to the beginning of the line.
    vim.fn.execute('normal zb', 'silent')
  else
    core.cursor.move(lnum)
  end
end

function M.loop_cursor_up(vfiler, context, view)
  local lnum = vim.fn.line('.') - 1
  if lnum < view:top_lnum() then
    lnum = view:num_lines()
  end
  core.cursor.move(lnum)
end

function M.move_cursor_bottom(vfiler, context, view)
  core.cursor.move(view:num_lines())
end

function M.move_cursor_bottom_sibling(vfiler, context, view)
  local lnum = view:last_sibling_item(vim.fn.line('.'))
  core.cursor.move(lnum)
end

function M.move_cursor_down(vfiler, context, view)
  local lnum = vim.fn.line('.') + 1
  core.cursor.move(lnum)
end

function M.move_cursor_down_sibling(vfiler, context, view)
  local lnum = view:next_sibling_item(vim.fn.line('.'))
  core.cursor.move(lnum)
end

function M.move_cursor_top(vfiler, context, view)
  core.cursor.move(view:top_lnum())
  -- Correspondence to show the header line
  -- when moving to the beginning of the line.
  vim.fn.execute('normal zb', 'silent')
end

function M.move_cursor_top_sibling(vfiler, context, view)
  local lnum = view:first_sibling_item(vim.fn.line('.'))
  core.cursor.move(lnum)
  -- Correspondence to show the header line
  -- when moving to the beginning of the line.
  vim.fn.execute('normal zb', 'silent')
end

function M.move_cursor_up(vfiler, context, view)
  local lnum = math.max(view:top_lnum(), vim.fn.line('.') - 1)
  core.cursor.move(lnum)
end

function M.move_cursor_up_sibling(vfiler, context, view)
  local lnum = view:prev_sibling_item(vim.fn.line('.'))
  core.cursor.move(lnum)
end

return M
