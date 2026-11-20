local spec_env = 'VFILER_TEST_SPEC'
local spec_color_env = 'VFILER_TEST_COLOR'
local spec_timeout = 50000

local status_colors = {
  PASS = 32,
  SKIP = 33,
  FAIL = 31,
  ERROR = 31,
  TIMEOUT = 33,
  INTERRUPTED = 33,
}

-- Use color in terminals and GitHub Actions, with overrides for redirected output.
local function use_color()
  if vim.env.NO_COLOR ~= nil then
    return false
  end
  if vim.env.FORCE_COLOR ~= nil then
    return vim.env.FORCE_COLOR ~= '0'
  end
  return vim.env.TERM ~= 'dumb'
    and (vim.env.GITHUB_ACTIONS == 'true' or vim.loop.guess_handle(1) == 'tty')
end

-- Keep file labels aligned while leaving nested labels compact.
local function status_label(status, colored, aligned)
  local label = aligned and ('%-11s'):format(status) or status
  if colored then
    return ('\27[%dm%s\27[0m'):format(status_colors[status], label)
  end
  return label
end

-- Format the counts shared by the child report and the final summary.
local function format_counts(result)
  return ('%d passed, %d failed, %d errors'):format(
    result.passed,
    result.failed,
    result.errors
  )
end

-- Indent each line of a test name or diagnostic within its suite.
local function write_indented(indent, message)
  local lines = message:gsub('\r\n', '\n'):gsub('\n', '\n' .. indent)
  io.stdout:write(indent, lines, '\n')
end

-- Display suites and their test results in the order they ran.
local function write_entries(entries, colored)
  for _, entry in ipairs(entries) do
    local indent = ('  '):rep(entry.depth + 1)
    if entry.kind == 'suite' then
      write_indented(indent, entry.name)
    elseif entry.kind == 'error' then
      write_indented(indent, status_label('ERROR', colored) .. ' ' .. entry.name)
      write_indented(indent .. '  ', entry.message)
    else
      local status = #entry.issues == 0 and 'PASS' or 'FAIL'
      write_indented(indent, status_label(status, colored) .. ' ' .. entry.name)
      for _, issue in ipairs(entry.issues) do
        local message = ('[%s] %s'):format(issue.phase, issue.message)
        write_indented(indent .. '  ', message)
      end
    end
  end
end

-- Run one spec in a fresh Neovim process and report its results.
local function run_spec(path, colored)
  vim.opt.runtimepath:append('.')
  -- Neovim 0.8 leaves file detection disabled with -u NONE.
  vim.cmd('filetype on')
  local result = require('tests/helper/spec').run(path)
  write_entries(result.entries, colored)

  local counts = {
    passed = result.passed,
    failed = #result.failures,
    errors = #result.errors,
  }
  io.stdout:write('Result: ', format_counts(counts), '\n')
  io.stdout:flush()
  return counts.failed == 0 and counts.errors == 0
end

-- Forward buffered job output and keep the next message on a new line.
local function write_lines(stream, lines)
  local output = table.concat(lines, '\n'):gsub('\r\n', '\n'):gsub('\r$', '')
  if output == '' then
    return
  end
  stream:write(output)
  if output:sub(-1) ~= '\n' then
    stream:write('\n')
  end
  stream:flush()
end

-- Run a spec in a child process and collect its counts and diagnostics.
local function run_child(path, colored)
  local result = { passed = 0, failed = 0, errors = 0, stdout = {}, stderr = {} }
  local reported = false
  local job = vim.fn.jobstart({
    vim.v.progpath,
    '--headless',
    '--noplugin',
    '-u', 'NONE',
    '-i', 'NONE',
    '-n',
    '-c', 'luafile tests/run.lua',
  }, {
    env = {
      [spec_env] = path,
      [spec_color_env] = colored and '1' or '0',
    },
    stdout_buffered = true,
    stderr_buffered = true,
    -- Keep the result line separate from the spec's own output.
    on_stdout = function(_, lines)
      for _, line in ipairs(lines) do
        local passed, failed, errors =
          line:match('^Result: (%d+) passed, (%d+) failed, (%d+) errors\r?$')
        if passed then
          result.passed = tonumber(passed)
          result.failed = tonumber(failed)
          result.errors = tonumber(errors)
          reported = true
        else
          table.insert(result.stdout, line)
        end
      end
    end,
    -- Preserve diagnostics even when a spec passes.
    on_stderr = function(_, lines)
      result.stderr = lines
    end,
  })
  if job <= 0 then
    result.status = 'ERROR'
    result.errors = 1
    result.message = 'Could not start Neovim.'
    return result
  end

  local code = vim.fn.jobwait({ job }, spec_timeout)[1]
  if code == -1 or code == -2 then
    vim.fn.jobstop(job)
    vim.fn.jobwait({ job }, 5000)
    result.status = code == -1 and 'TIMEOUT' or 'INTERRUPTED'
    result.message = code == -1 and 'Spec exceeded 50 seconds.' or 'Spec was interrupted.'
  elseif not reported then
    result.status = 'ERROR'
    result.message = ('Neovim exited with status %d before reporting a result.'):format(code)
  elseif result.errors > 0 then
    result.status = 'ERROR'
  elseif result.failed > 0 then
    result.status = 'FAIL'
  elseif code ~= 0 then
    result.status = 'ERROR'
    result.message = ('Neovim exited with status %d.'):format(code)
  else
    result.status = result.passed == 0 and 'SKIP' or 'PASS'
  end
  if result.message then
    result.errors = result.errors + 1
  end
  return result
end

-- Discover the specs and print the outcome of each file and the entire run.
local function run_all()
  local paths = vim.fn.glob('tests/vfiler/**/*_spec.lua', 1, 1)
  table.sort(paths)
  if #paths == 0 then
    io.stderr:write('No spec files found under tests/vfiler.\n')
    return false
  end

  local colored = use_color()
  local totals = { passed = 0, failed = 0, errors = 0 }
  local failed_files, skipped_files = 0, 0
  io.stdout:write(('Running %d spec files\n\n'):format(#paths))
  io.stdout:flush()
  for i, path in ipairs(paths) do
    local result = run_child(path, colored)
    totals.passed = totals.passed + result.passed
    totals.failed = totals.failed + result.failed
    totals.errors = totals.errors + result.errors
    if result.status == 'SKIP' then
      skipped_files = skipped_files + 1
    elseif result.status ~= 'PASS' then
      failed_files = failed_files + 1
    end

    io.stdout:write(('[%2d/%2d] %s %s (%s)\n'):format(
      i,
      #paths,
      status_label(result.status, colored, true),
      path,
      format_counts(result)
    ))
    io.stdout:flush()
    write_lines(io.stdout, result.stdout)
    write_lines(io.stderr, result.stderr)
    if result.message then
      io.stderr:write('  ', result.message, '\n')
      io.stderr:flush()
    end
    io.stdout:write('\n')
    io.stdout:flush()
  end
  io.stdout:write(('%s Total: %s (%d spec files, %d failed, %d skipped)\n'):format(
    status_label(failed_files == 0 and 'PASS' or 'FAIL', colored, true),
    format_counts(totals),
    #paths,
    failed_files,
    skipped_files
  ))
  io.stdout:flush()
  return failed_files == 0
end

-- Select child mode only when the parent supplies a spec path.
local function run()
  vim.o.shellslash = true
  local path = vim.env[spec_env]
  if path and path ~= '' then
    return run_spec(path, vim.env[spec_color_env] == '1')
  end
  return run_all()
end

local ok, success = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(success), '\n')
  io.stderr:flush()
end
vim.cmd(ok and success and 'qa!' or 'cquit 1')
