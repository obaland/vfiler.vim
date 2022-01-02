local core = require('vfiler/core')
local vim = require('vfiler/vim')

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

      if (tlower and vlower) or not (tlower or vlower) then
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

function M.compare_string(str2, str1)
  local length = math.min(#str1, #str2)
  for i = 1, length do
    local word1 = (str1:sub(i, i)):lower()
    local word2 = (str2:sub(i, i)):lower()

    if word2 < word1 then
      return true
    elseif word2 > word1 then
      return false
    end
  end
  return (#str2 - #str1) < 0
end

------------------------------------------------------------------------------
-- default sort collection
------------------------------------------------------------------------------

-- extension ascending
M.set('extension', function(item2, item1)
  if item2.isdirectory and not item1.isdirectory then
    return true
  elseif not item2.isdirectory and item1.isdirectory then
    return false
  elseif item2.isdirectory and item1.isdirectory then
    return M.compare_string(item2.name, item1.name)
  end

  local ext1 = vim.fn.fnamemodify(item1.name, ':e')
  local ext2 = vim.fn.fnamemodify(item2.name, ':e')
  if #ext1 == 0 and #ext2 == 0 then
    return M.compare_string(item2.name, item1.name)
  end
  return M.compare_string(ext2, ext1)
end)

-- name ascending
M.set('name', function(item2, item1)
  if item2.isdirectory and not item1.isdirectory then
    return true
  elseif not item2.isdirectory and item1.isdirectory then
    return false
  end
  return M.compare_string(item2.name, item1.name)
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
