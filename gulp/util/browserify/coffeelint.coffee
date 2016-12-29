_ = require 'lodash'
through = require 'through2'

coffeelint = require('coffeelint')
coffeelint.reporter = require('coffeelint-stylish').reporter #needed since default reporters blow up (coffeelint/lib/reporters/default)
coffeelint.configfinder = require('coffeelint/lib/configfinder')


###
custom coffeelint transform for browserify
###
module.exports = ({lintIgnore, watch, doSourceMaps}) ->
  (file, overrideOptions = {}) ->
    if (lintIgnore.filter [file]).length == 0
      file += '.ignore'

    errorReport = coffeelint.getErrorReport()
    fileOptions = coffeelint.configfinder.getConfig() or {}
    options = _.defaults(overrideOptions, fileOptions)

    options.doEmitErrors = !watch

    errors = null

    # Taken from browserify-coffeelint
    transform = (buf, enc, next) ->
      if file.substr(-7) == '.coffee'
        errors = errorReport.lint(file, buf.toString(), options)
        if errors.length != 0
          coffeelint.reporter file, errors
          if options.doEmitErrors and errorReport.hasError()
            next new Error(errors[0].message)
          if options.doEmitWarnings and _.any(errorReport.paths, (p) -> errorReport.pathHasWarning p)
            next new Error(errors[0].message)
      @push buf
      next()

    # If coffeelint found errors, append console.warns/errors to the end of the file
    # Additionally add a javascript alert (if this is the first file with errors), to draw attention to the console
    flush = (next) ->
      if errors?.length && doSourceMaps
        _.each errors, (error) =>
          {level, lineNumber, message} = error
          log = if level is 'error' then 'error' else 'warn'
          msg = "Coffeelint #{level} @ #{file}:#{lineNumber} #{message}".replace(/'/g, "\\'")
          @push "console.#{log} '#{msg}'\n"
          @push "alert window.lintAlert = 'LINT ERRORS SEE CONSOLE' if not window.lintAlert\n"

      next()

    through transform, flush
