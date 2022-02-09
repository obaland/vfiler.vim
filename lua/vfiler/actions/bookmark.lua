local util = require('vfiler/actions/utility')

local Bookmark = require('vfiler/extensions/bookmark')

local M = {}

function M.add_bookmark(vfiler, context, view)
  local item = view:get_current()
  Bookmark.add(item)
end

function M.list_bookmark(vfiler, context, view)
  local bookmark = Bookmark.new(vfiler, {
    on_selected = function(filer, c, v, path, open_type)
      util.open_file(filer, c, v, path, open_type)
    end,
  })
  util.start_extension(vfiler, context, view, bookmark)
end

return M
