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
function sorts.name(item2, item1)
  return item2.name < item1.name
end

return M
