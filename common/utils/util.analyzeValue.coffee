
getFunctionName = (funcString) ->
  # based off of http://stackoverflow.com/questions/332422/how-do-i-get-the-name-of-an-objects-type-in-javascript
  if not funcString then return null
  funcNameRegex = /function (.{1,})\(/
  results = (funcNameRegex).exec(funcString.toString())
  return if results && results.length > 1 then results[1] else ""

analyzeValue = (value) ->
  result = {}
  result.type = typeof(value)
  if result.type == 'undefined'
    # do nothing
  else if value == null
    result.type = 'null'
  else if result.type == 'function'
    result.verbose = value.toString()
    result.details = getFunctionName(result.verbose) || '<anonymous function>'
  else if result.type == 'object'
    if value instanceof Error
      result.type = value.name
      result.details = value.message
      if (value.stack?)
        result.verbose = (''+value.stack).split('\n').slice(1).join('\n')
    else
      result.type = null
    result.type = result.type || value?.constructor?.name || getFunctionName(value?.constructor?.toString()) || 'object'
    result.details = result.details || value.toString()
    if (result.details.substr(0, 7) == "[object" || result.type == 'Array')
      result.details = JSON.stringify value
  else if result.type == 'string'
    result.details = JSON.stringify value
  else # boolean, number, or symbol
    result.details = ''+value
  
  return result

module.exports = analyzeValue 