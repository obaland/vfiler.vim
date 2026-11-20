local M = {}

-- Raise an assertion error at the call site with the expected and actual values.
local function check(ok, relation, expected, actual, message)
  if ok then
    return
  end
  local detail = ('expected %s %s, got %s'):format(
    relation,
    vim.inspect(expected),
    vim.inspect(actual)
  )
  if message then
    detail = tostring(message) .. '\n' .. detail
  end
  error(detail, 3)
end

-- Check equality using Lua's equality operator.
local function equal(expected, actual, message)
  check(expected == actual, 'equal to', expected, actual, message)
end

-- Check inequality using Lua's equality operator.
local function not_equal(expected, actual, message)
  check(expected ~= actual, 'different from', expected, actual, message)
end

-- Compare values recursively for structural equality.
local function same(expected, actual, message)
  check(vim.deep_equal(expected, actual), 'equal to', expected, actual, message)
end

-- Reject nil while allowing false.
local function not_nil(actual, message)
  not_equal(nil, actual, message)
end

local assertions = setmetatable({
  are = { equal = equal, same = same },
  is_not = { equal = not_equal },
  equal = equal,
  is_equal = equal,
  not_equal = not_equal,
  is_not_nil = not_nil,
  not_nil = not_nil,
  -- Check that the value is nil.
  is_nil = function(actual, message)
    check(actual == nil, 'equal to', nil, actual, message)
  end,
  -- Require the boolean true.
  is_true = function(actual, message)
    check(actual == true, 'equal to', true, actual, message)
  end,
  -- Require the boolean false.
  is_false = function(actual, message)
    check(actual == false, 'equal to', false, actual, message)
  end,
}, {
  -- Preserve Lua's built-in assert call and its return values.
  __call = function(_, ...)
    return assert(...)
  end,
})

-- Attach a stack trace to a caught error.
local function traceback(err)
  return debug.traceback(tostring(err), 2)
end

-- Record a failure with its execution phase and report whether it succeeded.
local function attempt(issues, phase, fn)
  local ok, err = xpcall(fn, traceback)
  if not ok then
    table.insert(issues, { phase = phase, message = err })
  end
  return ok
end

-- Give unnamed tests and suites a usable label.
local function display_name(name)
  return name == nil and '(unnamed)' or tostring(name)
end

-- Run a spec file with its own test helpers and collect the results.
function M.run(path)
  local result = { passed = 0, failures = {}, errors = {}, entries = {} }

  -- Keep suite and load errors in display order as well as in the error total.
  local function record_error(name, qualified_name, depth, message)
    table.insert(result.errors, { name = qualified_name, message = message })
    table.insert(result.entries, {
      kind = 'error',
      name = name,
      depth = depth,
      message = message,
    })
  end

  local chunk, err = loadfile(path)
  if not chunk then
    record_error(path, path, 0, err)
    return result
  end

  local scopes = {}

  -- Qualify a test or suite name with its parent suite name.
  local function full_name(name)
    local parent = scopes[#scopes]
    if parent then
      return parent.name .. ' ' .. name
    end
    return name
  end

  -- Run a suite immediately and keep its hooks scoped to that suite.
  local function describe(name, body)
    name = display_name(name)
    table.insert(result.entries, { kind = 'suite', name = name, depth = #scopes })
    local scope = { name = full_name(name), before = {}, after = {} }
    table.insert(scopes, scope)
    local ok, describe_error = xpcall(body, traceback)
    table.remove(scopes)
    if not ok then
      record_error(name, scope.name, #scopes + 1, describe_error)
    end
  end

  -- Run one test with its hooks and record the outcome.
  local function it(name, body)
    name = display_name(name)
    local issues = {}
    local entered = 0
    -- Track each scope entered during setup so its cleanup hooks can run.
    local ready = attempt(issues, 'before_each', function()
      for i, scope in ipairs(scopes) do
        entered = i
        for _, hook in ipairs(scope.before) do
          hook()
        end
      end
    end)
    if ready then
      attempt(issues, 'test', body)
    end

    for i = 1, entered do
      for _, hook in ipairs(scopes[i].after) do
        attempt(issues, 'after_each', hook)
      end
    end

    table.insert(result.entries, {
      kind = 'test',
      name = name,
      depth = #scopes,
      issues = issues,
    })
    if #issues == 0 then
      result.passed = result.passed + 1
    else
      table.insert(result.failures, { name = full_name(name), issues = issues })
    end
  end

  setfenv(chunk, setmetatable({
    assert = assertions,
    describe = describe,
    it = it,
    -- Register a setup hook for the current suite.
    before_each = function(hook)
      table.insert(scopes[#scopes].before, hook)
    end,
    -- Register a cleanup hook for the current suite.
    after_each = function(hook)
      table.insert(scopes[#scopes].after, hook)
    end,
  }, { __index = _G }))

  local ok, run_error = xpcall(chunk, traceback)
  if not ok then
    record_error(path, path, 0, run_error)
  end
  return result
end

return M
