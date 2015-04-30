_ = require 'lodash'
through = require('through')


module.exports =
  
  objectsToPgText: (fields, _options={}) ->
    defaults =
      null: '\\N'
      delimiter: '\t'
      encoding: 'utf-8'
    options = _.extend({}, defaults, _options)
    write = (obj) ->
      parts = _.map fields, (field) ->
        val = obj[field]
        if !val?
          return options.null
        else
          return val.replace(/\\/g, '\\\\')
          .replace(/\n/g, '\\n')
          .replace(/\r/g, '\\r')
          .replace(new RegExp(options.delimiter, 'g'), '\\'+options.delimiter)
      @queue parts.join(options.delimiter)+'\n'
    end = () ->
      @queue new Buffer('\\.\n')
      @queue null
    through(write, end)
