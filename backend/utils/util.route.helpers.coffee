methodExec = (req, methods) ->
  do(methods[req.method] or -> next(badRequest("HTTP METHOD: #{req.method} not supported for route.")))

module.exports =
  methodExec: methodExec
