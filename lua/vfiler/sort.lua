local core = require('vfiler/libs/core')
local vim = require('vfiler/libs/vim')

local M = {}

M.compares = {}

local function to_desc_name(type)
  return (type:sub(1, 1)):upper() .. type:sub(2)
end

--- Get sort type comparison function.
---@param type string
---@return function?: Return `nil` if sort type is not set.
function M.get(type)
  local compare = M.compares[type]

  if not compare then
    core.message.error('Invalid sort type "%s"', type)
    return nil
  end
  return compare
end

--- Set specific information about the sorting.
---@param type string
---@param compare function
function M.set(type, compare)
  M.compares[type] = compare
  -- set descending order at the same time
  local desc_name = to_desc_name(type)
  M.compares[desc_name] = function(item1, item2)
    return compare(item2, item1)
  end
end

--- Obtain sort type in list format.
---@return table
function M.types()
  local types = {}
  for type, _ in pairs(M.compares) do
    local tlower = type:match('^%l') ~= nil
    local pos = #types + 1
    for i, value in ipairs(types) do
      local vlower = value:match('^%l') ~= nil
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

------------------------------------------------------------------------------
-- default sort collection
------------------------------------------------------------------------------

local function compare_string(str1, str2)
  local length = math.min(#str1, #str2)
  for i = 1, length do
    local word1 = (str1:sub(i, i)):lower()
    local word2 = (str2:sub(i, i)):lower()

    if word1 < word2 then
      return true
    elseif word1 > word2 then
      return false
    end
  end
  return (#str1 - #str2) < 0
end

-- extension ascending
M.set('extension', function(item1, item2)
  local is_dir1 = item1.type == 'directory'
  local is_dir2 = item2.type == 'directory'
  if is_dir1 and not is_dir2 then
    return true
  elseif not is_dir1 and is_dir2 then
    return false
  elseif is_dir1 and is_dir2 then
    return compare_string(item1.name, item2.name)
  end

  local ext1 = vim.fn.fnamemodify(item1.name, ':e')
  local ext2 = vim.fn.fnamemodify(item2.name, ':e')
  if (#ext1 == 0 and #ext2 == 0) or (ext1:lower() == ext2:lower()) then
    return compare_string(item1.name, item2.name)
  end
  return compare_string(ext1, ext2)
end)

-- name ascending
M.set('name', function(item1, item2)
  local is_dir1 = item1.type == 'directory'
  local is_dir2 = item2.type == 'directory'
  if is_dir1 and not is_dir2 then
    return true
  elseif not is_dir1 and is_dir2 then
    return false
  end
  return compare_string(item1.name, item2.name)
end)

-- size ascending
M.set('size', function(item1, item2)
  if item1.size == item2.size then
    return M.compares.name(item1, item2)
  end
  return item1.size < item2.size
end)

-- time ascending
M.set('time', function(item1, item2)
  if item1.time == item2.time then
    return M.compares.name(item1, item2)
  end
  return item1.time < item2.time
end)

return M
