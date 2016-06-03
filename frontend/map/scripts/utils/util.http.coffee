msie = document.documentMode
###
  PLEASE NOTE!

  For the majority of client side request $http should be used. Only use this if
  angular does not meet your needs and you need minimum security and browser support.

  using callback to not pull in bluebird, if you really want promises then pull in Q or use native (es6)promises

  Big differences:
  - little to no security measures (allow cross origin)
  - defaults to synchronous
  - no cache
###

isSuccess = (status) ->
  200 <= status and status < 300

#doing native http request without angular since only async is supported in ng
#http://stackoverflow.com/questions/247483/http-get-request-in-javascript

APPLICATION_JSON = 'application/json'
CONTENT_TYPE_APPLICATION_JSON = {'Content-Type': APPLICATION_JSON + ';charset=utf-8'}

###*
#
# Implementation Notes for non-IE browsers
# ----------------------------------------
# Assigning a URL to the href property of an anchor DOM node, even one attached to the DOM,
# results both in the normalizing and parsing of the URL.  Normalizing means that a relative
# URL will be resolved into an absolute URL in the context of the application document.
# Parsing means that the anchor node's host, hostname, protocol, port, pathname and related
# properties are all populated to reflect the normalized URL.  This approach has wide
# compatibility - Safari 1+, Mozilla 1+, Opera 7+,e etc.  See
# http://www.aptana.com/reference/html/api/HTMLAnchorElement.html
#
# Implementation Notes for IE
# ---------------------------
# IE >= 8 and <= 10 normalizes the URL when assigned to the anchor node similar to the other
# browsers.  However, the parsed components will not be set if the URL assigned did not specify
# them.  (e.g. if you assign a.href = "foo", then a.protocol, a.host, etc. will be empty.)  We
# work around that by performing the parsing in a 2nd step by taking a previously normalized
# URL (e.g. by assigning to a.href) and assigning it a.href again.  This correctly populates the
# properties such as protocol, hostname, port, etc.
#
# IE7 does not normalize the URL when assigned to an anchor node.  (Apparently, it does, if one
# uses the inner HTML approach to assign the URL as part of an HTML snippet -
# http://stackoverflow.com/a/472729)  However, setting img[src] does normalize the URL.
# Unfortunately, setting img[src] to something like "javascript:foo" on IE throws an exception.
# Since the primary usage for normalizing URLs is to sanitize such URLs, we can't use that
# method and IE < 8 is unsupported.
#
# References:
#   http://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement
#   http://www.aptana.com/reference/html/api/HTMLAnchorElement.html
#   http://url.spec.whatwg.org/#urlutils
#   https://github.com/angular/angular.js/pull/2902
#   http://james.padolsey.com/javascript/parsing-urls-with-the-dom/
#
# @kind function
# @param {string} url The URL to be parsed.
# @description Normalizes and parses a URL.
# @returns {object} Returns the normalized URL as a dictionary.
#
#   | member name   | Description    |
#   |---------------|----------------|
#   | href          | A normalized version of the provided URL if it was not an absolute URL |
#   | protocol      | The protocol including the trailing colon                              |
#   | host          | The host and port (if the port is non-default) of the normalizedUrl    |
#   | search        | The search params, minus the question mark                             |
#   | hash          | The hash string, minus the hash symbol
#   | hostname      | The hostname
#   | port          | The port, without ":"
#   | pathname      | The pathname, beginning with "/"
#
###

urlResolve = (url) ->
  href = url
  if msie
# Normalize before parse.  Refer Implementation Notes on why this is
# done in two steps on IE.
    urlParsingNode.setAttribute 'href', href
    href = urlParsingNode.href
  urlParsingNode.setAttribute 'href', href
  # urlParsingNode provides the UrlUtils interface - http://url.spec.whatwg.org/#urlutils
  {
  href: urlParsingNode.href
  protocol: if urlParsingNode.protocol then urlParsingNode.protocol.replace(/:$/, '') else ''
  host: urlParsingNode.host
  search: if urlParsingNode.search then urlParsingNode.search.replace(/^\?/, '') else ''
  hash: if urlParsingNode.hash then urlParsingNode.hash.replace(/^#/, '') else ''
  hostname: urlParsingNode.hostname
  port: urlParsingNode.port
  pathname: if urlParsingNode.pathname.charAt(0) == '/' then urlParsingNode.pathname else '/' + urlParsingNode.pathname
  }
# NOTE:  The usage of window and document instead of $window and $document here is
# deliberate.  This service depends on the specific behavior of anchor nodes created by the
# browser (resolving and parsing URLs) that is unlikely to be provided by mock objects and
# cause us to break tests.  In addition, when the browser resolves a URL for XHR, it
# doesn't know about mocked locations and resolves URLs to the real document - which is
# exactly the behavior needed here.  There is little value is mocking these out for this
# service.
urlParsingNode = document.createElement('a')
originUrl = urlResolve(window.location.href)

createXhr = ->
  new XMLHttpRequest()


_httpOptionsErrorMsg = (optStr = '') ->
  "http options #{optStr} must be defined"

_requiredOpts = [undefined,'method', 'url', 'isAsync']

_http = (opts, cb) ->
  return '' if window.isTest
  for key,val of _requiredOpts
    toCheck = if val? then opts[val] else opts
    if !toCheck?
      throw new Error(_httpOptionsErrorMsg(val))

  xhr = createXhr()
  xhr.open(opts.method, opts.url, opts.isAsync)
  headers = _.extend {}, CONTENT_TYPE_APPLICATION_JSON
  for key, val of headers
    xhr.setRequestHeader(key, val)

  if cb?
    xhr.onload = -> #copied from angular
      statusText = xhr.statusText or ''
      # responseText is the old-school way of retrieving response (supported by IE8 & 9)
      # response/responseType properties were introduced in XHR Level2 spec (supported by IE10)
      response = if 'response' of xhr then xhr.response else xhr.responseText
      # normalize IE9 bug (http://bugs.jquery.com/ticket/1450)
      status = if xhr.status == 1223 then 204 else xhr.status
      # fix status code when it is 0 (0 status is undocumented).
      # Occurs when accessing file resources or on Android 4.1 stock browser
      # while retrieving files from application cache.
      if status == 0
        status = if response then 200 else if urlResolve(url).protocol == 'file' then 404 else 0

      if !isSuccess(status)
        err = statusText
      cb(err, status, response, xhr.getAllResponseHeaders(), statusText)
      return

  xhr.send(opts.data || null)

  return xhr.responseText unless cb?

get = ({url, isAsync}, cb) ->
  isAsync ?= false
  _http({method:'GET', url, isAsync}, cb)

post = ({url, isAsync, data}, cb) ->
  isAsync ?= false

  opts = {method:'POST', url, isAsync, data}
  _http opts, cb


module.exports = {
  get
  post
}
