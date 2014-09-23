module.exports =
  SqlTypeError:
    class SqlTypeError extends Error
      constructor: (@message) ->
        @name = "SqlTypeError"
        Error.captureStackTrace(this, SqlTypeError)