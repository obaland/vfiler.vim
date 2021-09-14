local M = {}

M.fn = vim.fn
if vim.fn.has('nvim') == 1 then
  M.command = vim.api.nvim_command
else
  M.command = vim.command
end

function M.warning(message)
  M.api.command(
    string.format('echohl WarningMsg | echo "%s" | echohl None', message)
  )
end

--[[
function! vfiler#core#normalized_path(path) abort
  if a:path ==? '/'
    return '/'
  endif

  let result = resolve(a:path)

  " trim trailing path separator
  return (match(result, '\(/\|\\\)$') >= 0)
        \ ? fnamemodify(result, ':h')
        \ : result
endfunction
]]

function M.normalized_path(path)
  if path == '/' then
    return '/'
  end
  -- trim trailing path separator
  local result = vim.fn.resolve(path)
  if string.match(result, '/$') or string.match(result, '\\$') then
    result = vim.fn.fnamemodify(result, ':h')
  end
  return result
end

return M
