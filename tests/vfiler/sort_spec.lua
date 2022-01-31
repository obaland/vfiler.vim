local sort = require('vfiler/sort')

describe('API', function()
  it('types', function()
    local expected_types = {
      'extension',
      'name',
      'size',
      'time',
      'Extension',
      'Name',
      'Size',
      'Time',
    }
    local types = sort.types()
    for i = 1, #expected_types do
      assert.is_equal(expected_types[i], types[i])
    end
  end)
end)
