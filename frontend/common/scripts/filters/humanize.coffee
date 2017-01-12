mod = require '../module.coffee'

# http://stackoverflow.com/questions/4149276/javascript-camelcase-to-regular-form
mod.filter 'humanize', () ->
  (input) ->
    # sanity check
    if !input? or !input
      return 'Empty'
    # do nothing if all caps (implies accronym or something)
    if input == input.toUpperCase()
      return input

    # convert to camelCase from `snake-case`
    if input.indexOf('-') >= 0
      input = input.replace(/(\-\w)/g, (m) -> m[1].toUpperCase())
    # or convert to camelCase from `snake_case`
    else if input.indexOf('_') >= 0
      input = input.replace(/(\_\w)/g, (m) -> m[1].toUpperCase())

    # humanize camelCase
    input
    # insert a space before all caps
    .replace /([A-Z])/g, ' $1'
    # uppercase the first character
    .replace /^./, (str) -> str.toUpperCase()
