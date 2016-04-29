_ = require 'lodash'
Promise = require 'bluebird'
logger = require '../../config/logger'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    if !value
      return null
    parts = []
    stories = value.match(/\d+(?:\.\d+)?/)
    if stories?[0]
      parts.push(stories?[0])
      if value.indexOf('/L') != -1
        parts.push('Split Levels')
      else
        parts.push('Stories')
    else if value.indexOf('S/L') != -1
      parts.push('Split Level')
    else if value.indexOf('B/L') != -1
      parts.push('Bi-Level')
    else if value.indexOf('S/E') != -1
      parts.push('Split Entry')
    else if value.indexOf('S/F') != -1
      parts.push('Split Foyer')

    attic = value.indexOf('A') != -1
    basement = value.match(/(?:B[^/])|(?:B$)/)?
    if attic && basement
      parts.push('with Attic and Basement')
    else
      if attic
        parts.push('with Attic')
      else if basement
        parts.push('with Basement')

    if parts.length == 0
      return value  # just pass it through
    else
      return parts.join(' ')
