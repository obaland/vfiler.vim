local M = {}

local sorts = {}

local function to_desc_name(name)
  return (name:sub(1, 1)):upper() .. name:sub(2)
end

function M.get(name)
  return sorts[name]
end

function M.set(name, compare)
  sorts[name] = compare
  -- set descending order at the same time
  local desc_name = to_desc_name(name)
  sorts[desc_name] = function(item2, item1)
      return not compare(item2, item1)
  end
end

------------------------------------------------------------------------------
-- default sort collection
------------------------------------------------------------------------------

-- name ascending
M.set('name', function(item2, item1)
  if item2.isdirectory and not item1.isdirectory then
    return true
  elseif not item2.isdirectory and item1.isdirectory then
    return false
  end
  return item2.name < item1.name
end)

-- size ascending
M.set('size', function(item2, item1)
  if item2.size == item1.size then
    return sorts.name(item2, item1)
  end
  return item2.size < item1.size
end)

-- time ascending
M.set('time', function(item2, item1)
  if item2.time == item1.time then
    return sorts.name(item2, item1)
  end
  return item2.time < item1.time
end)

return M
