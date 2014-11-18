space = " "
#console.log "String obj: #{String}"
String::contains = (value,fromIndex) ->
  @indexOf(value,fromIndex) != -1

String::ourNameSpace = (flare = 'RealtyMaps-') ->
  flare + '-' + @

#String::ns = String::flare used by angular-google-maps in 2.0.0
String::ourNs = String::ourNameSpace

String::space = ->
  @ + space

String::EMPTY = ''
