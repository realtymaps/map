#doing native http request without angular since only async is supported in ng
#http://stackoverflow.com/questions/247483/http-get-request-in-javascript
module.exports =
  get: (theUrl, isAsync = false) ->
    xmlHttp = new XMLHttpRequest()
    xmlHttp.open("GET", theUrl, isAsync)
    xmlHttp.send(null)
    xmlHttp.responseText
