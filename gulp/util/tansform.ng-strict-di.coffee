_ = require 'lodash'
through = require 'through2'
logger = require('./logger').spawn("util:transform:ng-strict-di")
{PartiallyHandledError} = require '../../backend/utils/errors/util.error.partiallyHandledError'


class MissingNgInitError extends PartiallyHandledError
  constructor: (@file, @badContents, args...) ->
    defaultMsg = 'Strict DI ngInit missing: '
    @stringContents = @file.contents.toString()
    @getLineNumber()

    if typeof args[0] == 'string'
      [msg] = args

      msg = "#{msg} #{defaultMsg}"

    msg ?= defaultMsg

    msg = "#{msg} at filename: #{@file.basename} lineNumber: #{@lineNumber}, contents: #{@badContents}"


    super('MissingNgInitError', args...)
    @message = msg

  getLineNumber: () ->
    clrf = /(.*)?\n/g
    contents = @stringContents.match(clrf)
    badContents = @badContents.match(clrf)

    for content, i in contents
      if content == badContents[0]
        nextIndex = i + 1
        if nextIndex < contents.length
          contents[nextIndex] == badContents[1]
          @lineNumber = i + 1
          break

isCoffee = (filename) ->
  /\.((lit)?coffee|coffee\.md)$/.test(filename)

isJS = (filename) ->
  /\.(js)$/.test(filename)

isAngularInjection = (contents) ->
  #we look for areas that are easily injectable by ng-annotate
  angularInjectables = ['service', 'provider', 'factory', 'directive', 'run']
  _.any angularInjectables, (injectName) ->
    reg = new RegExp(".*\\.#{injectName}")
    reg.test(contents)

transform = (filename, {matches, skips} = {}) ->
  if matches? && !Array.isArray(matches)
    matches = [matches]
  if skips? && !Array.isArray(skips)
    skips = [skips]

  if _.any(matches, (s) -> !s.test(filename))
    return through()

  if _.any(skips, (s) -> s.test(filename))
    return through()

  if !isCoffee(filename) && !isJS(filename)
    return through()

  enforceStrict = (origContents, enc, cb) ->

    contents = origContents.toString()

    logger.debug -> "ng-strict-di checking: filename: #{filename}"


    #TODO: Do more than check just $templateCache without ngInject
    #line with possible problem and then the next line with or without a following \n
    regex = /(.*)?\((.*)?\$templateCache(.*\))?.*\n.*(\n)?/g

    matches = contents.match(regex)

    if !matches?
      @push(origContents)
      return cb()

    # logger.debug -> "@@@@@@@ ALL MATCHES @@@@@@@"
    # logger.debug -> matches.length
    # logger.debug -> matches

    badContents = null
    for toCheck, i in matches
      if !/ngInject/g.test(toCheck) && !isAngularInjection(toCheck)
        badContents = toCheck
        break

    if badContents?
      err =  new MissingNgInitError({basename:filename, contents}, badContents)
      return cb(err.message)

    @push(origContents)
    cb()

  through.obj enforceStrict

module.exports = transform
