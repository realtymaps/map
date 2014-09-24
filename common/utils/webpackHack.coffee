module.exports =
  ###
  Since webpack relies on search and replace of require 'string' or require "string".
  Calling require via another function hides the reuirement from webpack.

  I found this out originally when I tried making a requires iterator which did not work.

  But that failure led to this success : )
  ###
  hiddenRequire: (dep) ->
    require dep
