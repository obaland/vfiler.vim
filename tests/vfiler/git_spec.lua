local core = require('vfiler/libs/core')

local Git = require('vfiler/git')

describe('Git', function()
  it('status_async', function()
    local git = Git.new({})
    git:status_async(core.path.normalize('./'), function(self, root, status)
      assert.is_not_nil(self)
      assert.is_not_nil(root)
      assert.is_not_nil(status)
    end)
  end)

  it('reset', function()
    local git = Git.new({})
    git:reset({})
  end)

  it('status', function()
    local git = Git.new({})
    git:status(core.path.normalize('./'))
  end)

  it('walk_status', function()
    local git = Git.new({})
    for path, status in git:walk_status() do
      assert.is_not_nil(path)
      assert.is_not_nil(status)
    end
  end)
end)
