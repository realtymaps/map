rewire = require 'rewire'
jobQueueHelper = require '../../specUtils/jobQueue'

bk = rewire '../../../backend/tasks/task.blackknight'
bkInternals = rewire '../../../backend/tasks/task.blackknight.internals'


# filterS3Contents()
# contents:
# [{
#   "Key": "Managed_Refresh/ASMT20160330/12021_Assessment_Refresh_20160330.txt.gz",
#   "LastModified": "2016-08-12T01:15:06.000Z",
#   "ETag": "\"6d7afac3a43edf7fd2976996358a4f0c-8\"",
#   "Size": 41085757,
#   "StorageClass": "STANDARD"
# }]
# config:
# {
#   "action": "Refresh",
#   "tableId": "ASMT",
#   "date": "20160330",
#   "startTime": 1471390732735
# }


describe 'bk test!', () ->

  beforeEach ->
    console.log "\n\nbk testing..."

  it 'passes sanity check', ->
    newBk = jobQueueHelper(bk)
    console.log "passing sanity check"