mod = require '../module.coffee'

# http://stackoverflow.com/questions/4149276/javascript-camelcase-to-regular-form
mod.filter 'camelToHuman', () ->
  (input) ->
    # sanity check
    if !input? or !input
      return 'Empty'
    # do nothing if all caps (implies accronym or something)
    if input == input.toUpperCase()
      return input

    input
    # insert a space before all caps
    .replace /([A-Z])/g, ' $1'
    # uppercase the first character
    .replace /^./, (str) -> str.toUpperCase()
