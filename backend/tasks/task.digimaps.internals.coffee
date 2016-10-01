Promise = require 'bluebird'
_ = require 'lodash'
externalAccounts = require '../services/service.externalAccounts'
parcelsFetch = require '../services/service.parcels.fetcher.digimaps'
logger = require('../config/logger.coffee').spawn('task:digimaps:internals')
importsLogger = logger.spawn('imports')
filteredLogger = logger.spawn('filtered')
moment = require 'moment'

NUM_ROWS_TO_PAGINATE = 1000
DELAY_MILLISECONDS = 250

LAST_PROCESS_DATE = 'last process date'
NO_NEW_DATA_FOUND = 'no new data found'
QUEUED_FILES = 'queued files'
DIGIMAPS_PROCESS_INFO = 'digimaps process info'

getFileDate = (filename) ->
  return filename.split('/')[2].split('_')[2]

getFileFips = (filename) ->
  return filename.split('/')[4].slice(8,13)

filterImports = (subtask, imports, refreshThreshold) ->
  importsLogger.debug () -> imports

  folderObjs = imports.map (l) ->
    name: l
    date: getFileDate(l)

  if refreshThreshold? && !subtask.data.skipRefreshThreshold
    logger.debug -> '@@@ refreshThreshold @@@'
    logger.debug -> refreshThreshold

    folderObjs = _.filter folderObjs, (o) ->
      o.date > refreshThreshold

    if subtask.data.fipsCodeLimit?
      logger.debug () -> "@@@@@@@@@@@@@ fipsCodeLimit: #{subtask.data.fipsCodeLimit}"
      folderObjs = _.take folderObjs, subtask.data.fipsCodeLimit

    fileNames = folderObjs.map (f) -> f.name
    fileNames.sort()
    fipsCodes = fileNames.map (name) -> getFileFips(name)

    logger.debug -> "@@@@@@@@@@@@@@@@@@@@@@@@@ fipsCodes Available from digimaps @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    logger.debug -> fipsCodes

    # Filter to specific fipsCodes in an Array
    if subtask.data.fipsCodes? && Array.isArray subtask.data.fipsCodes
      fileNames = _.filter fileNames, (name) ->
        _.any subtask.data.fipsCodes, (code) ->
          name.endsWith("_#{code}.zip")

      fipsCodes = fileNames.map (name) -> getFileFips(name)

    if subtask.data.fipsCodesRange?.start? && subtask.data.fipsCodesRange.end?
      start = parseInt subtask.data.fipsCodesRange.start
      end = parseInt subtask.data.fipsCodesRange.end
      fileNames = _.filter fileNames, (name) ->
        code = parseInt(getFileFips(name))
        start <= code <= end

      fipsCodes = fileNames.map (name) -> getFileFips(name)

    if subtask.data.fipsCodesRegExp?
      {fipsCodesRegExp} = subtask.data
      if !Array.isArray(fipsCodesRegExp)
        fipsCodesRegExp = [fipsCodesRegExp]

      logger.debug -> "@@@@@@@@@@@@@@@@@@@@@@@@@ fipsCodesRegExp  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      fileNames = _.filter fileNames, (name) ->
        code = getFileFips(name)
        _.any fipsCodesRegExp, (regexStr) ->
          RegExp(regexStr).test(code)


      fipsCodes = fileNames.map (name) -> getFileFips(name)

    filteredLogger.debug -> "@@@@@@@@@@@@@@@@@@@@@@@@@ filtered fipsCodes  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    filteredLogger.debug -> fipsCodes

    return fileNames

getLoadFile = (subtask, processInfo) -> Promise.try () ->
  now = Date.now()

  if processInfo[QUEUED_FILES].length > 0
    return {
      load:
        fileName: processInfo[QUEUED_FILES][0]
        startTime: now
      processInfo
    }
  else
    externalAccounts.getAccountInfo(subtask.task_name)
    .then (creds) ->
      parcelsFetch.defineImports({creds})
    .then (imports) ->
      filterImports(subtask, imports, processInfo[LAST_PROCESS_DATE])
    .then (filteredImports) ->
      if filteredImports.length == 0
        processInfo[NO_NEW_DATA_FOUND] = moment.utc().format('YYYYMMDD')
        return {
          load: null
          processInfo
        }
      else
        processInfo[QUEUED_FILES] = filteredImports
        nextFile = filteredImports[0]
        processInfo[LAST_PROCESS_DATE] = getFileDate(nextFile)
        return {
          load:
            fileName: nextFile
            startTime: now
          processInfo
        }

module.exports = {
  getFileDate
  getFileFips
  filterImports
  getLoadFile
  NUM_ROWS_TO_PAGINATE
  DELAY_MILLISECONDS
  LAST_PROCESS_DATE
  NO_NEW_DATA_FOUND
  QUEUED_FILES
  DIGIMAPS_PROCESS_INFO
}
