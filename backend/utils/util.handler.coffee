handler = ({args, handles}, handleNameCb) ->
  handleName = handleNameCb()
  handle = handles[handleName] or handles.default or () ->
  handle(args...)

module.exports = handler
