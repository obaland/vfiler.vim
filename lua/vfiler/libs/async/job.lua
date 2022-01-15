local vim = require('vfiler/libs/vim')

local Job
if vim.fn.has('nvim') == 1 then
  Job = require('vfiler/libs/async/job/nvim')
else
  Job = require('vfiler/libs/async/job/vim')
end

return Job
