space = " "
#console.log "String obj: #{String}"
String::contains = (value,fromIndex) ->
  @indexOf(value,fromIndex) != -1

String::ourNameSpace = (flare = 'rmaps') ->
  flare + @

#String::ns = String::flare used by angular-google-maps in 2.0.0
String::ourNs = String::ourNameSpace

String::space = ->
  @ + space

String::EMPTY = ''

String.orNA = (val) ->
  val or 'N/A'

String.orDash = (val) ->
  val or '-'

String::replaceLast = (find, replace) ->
  index = @lastIndexOf(find);
  if index >= 0
      return @substring(0, index) + replace + @substring(index + find.length);

  return @toString();
