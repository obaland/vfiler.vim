local sort = require('vfiler/sort')

local sort_types = {
  'extension',
  'name',
  'size',
  'time',
  'Extension',
  'Name',
  'Size',
  'Time',
}

describe('API', function()
  it('types', function()
    local types = sort.types()
    for i = 1, #sort_types do
      assert.is_equal(sort_types[i], types[i])
    end
  end)

  -- test "get" function
  for _, type in ipairs(sort_types) do
    it('get type: ' .. type, function()
      local comp = sort.get(type)
      assert.is_not_nil(comp)
    end)
  end

  it('set', function()
    sort.set('user', function() end)
    assert.is_not_nil(sort.get('user'))
    assert.is_not_nil(sort.get('User'))
  end)
end)
