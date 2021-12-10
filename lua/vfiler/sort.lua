local core = require('vfiler/core')

local M = {}

M.compares = {}

local function to_desc_name(type)
  return (type:sub(1, 1)):upper() .. type:sub(2)
end

---@param type string
function M.get(type)
  local compare = M.compares[type]

  if not compare then
    core.message.error('Invalid sort type "%s"', type)
    return nil
  end
  return compare
end

-- @param type    string
-- @param compare function
function M.set(type, compare)
  M.compares[type] = compare
  -- set descending order at the same time
  local desc_name = to_desc_name(type)
  M.compares[desc_name] = function(item2, item1)
      return compare(item1, item2)
  end
end

function M.types()
  local types = {}
  for type, _ in pairs(M.compares) do
    local tfirst = type:byte(1, 1)
    local tlower = (0x61 <= tfirst) and (tfirst <= 0x7A)

    local pos = #types + 1
    for i, value in ipairs(types) do
      local vfirst = value:byte(1, 1)
      local vlower = (0x61 <= vfirst) and (vfirst <= 0x7A)

      if (tlower and vlower) or (not (tlower or vlower)) then
        if type < value then
          pos = i
          break
        end
      elseif tlower then
        pos = i
        break
      end
    end
    table.insert(types, pos, type)
  end
  return types
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

  local name1 = item1.name
  local name2 = item2.name
  local length = math.min(#name1, #name2)

  for i = 1, length do
    local word1 = (name1:sub(i, i)):lower()
    local word2 = (name2:sub(i, i)):lower()

    if word2 < word1 then
      return true
    elseif word2 > word1 then
      return false
    end
  end
  return (#name2 - #name1) < 0
end)

-- size ascending
M.set('size', function(item2, item1)
  if item2.size == item1.size then
    return M.compares.name(item2, item1)
  end
  return item2.size < item1.size
end)

-- time ascending
M.set('time', function(item2, item1)
  if item2.time == item1.time then
    return M.compares.name(item2, item1)
  end
  return item2.time < item1.time
end)

return M
