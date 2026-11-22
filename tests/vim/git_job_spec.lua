local core = require('vfiler/libs/core')
local git = require('vfiler/libs/git')

assert(not core.is_nvim)

local directory = vim.fn.tempname()
assert(vim.fn.mkdir(directory, 'p') == 1)
local root = core.path.normalize(directory)
local ok, err = xpcall(function()
  local output = vim.fn.system('git -C ' .. vim.fn.shellescape(root) .. ' init -q')
  assert(vim.v.shell_error == 0, output)
  assert(vim.fn.writefile(vim.list({ 'content' }), root .. 'new.txt') == 0)

  local actual_root
  local root_job = assert(git.root_async(root, function(path)
    actual_root = path
  end), 'could not start Git root lookup')
  root_job:wait(5000)
  assert(actual_root == root, 'unexpected asynchronous Git root: ' .. tostring(actual_root))

  local statuses
  local status_job = assert(git.status_async(root, { untracked = true }, function(result)
    statuses = result
  end), 'could not start Git status')
  status_job:wait(5000)
  local status = assert(statuses and statuses[root .. 'new.txt'], 'missing Git status for new.txt')
  assert(status.us == '?' and status.them == '?')
end, debug.traceback)
vim.fn.delete(directory, 'rf')
assert(ok, err)
