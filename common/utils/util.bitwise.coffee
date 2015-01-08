module.exports =
  XOR: (a,b) ->
    return ( a || b ) && !( a && b );
