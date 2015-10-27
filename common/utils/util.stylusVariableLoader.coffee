
# there are some edge cases this doesn't exactly handle, namely block comments with // prior to the comment
# terminator.  Also, the entire variable assignment has to be on a single line.  But that should be good enough.

module.exports = (content) ->
  @cacheable?()
  @value = {}

  # remove single-line comments
  content = content.replace(/\/\/.*/g, '')
  # remove block comments
  content = content.replace(/\/\*[^*]*(?:\*+[^/])*[^*]*\*\//g, '')

  lines = content.split('\n')
  for line in lines
    parts = line.split('=', 2)
    if parts.length != 2
      continue
    @value[parts[0].trim()] = parts[1].trim()

  return @value
