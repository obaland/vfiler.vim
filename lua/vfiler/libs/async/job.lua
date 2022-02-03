local core = require('vfiler/libs/core')

local Job
if core.is_nvim then
  Job = require('vfiler/libs/async/jobs/job_nvim')
else
  Job = require('vfiler/libs/async/jobs/job_vim')
end

return Job
