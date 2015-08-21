VError = require 'verror'
FtpClient = require 'ftp'
_ = require 'lodash'
Promise = require "bluebird"


class FtpConnectionError extends VError
  constructor: (args...) ->
    super(args...)
    @name = 'FtpConnectionError'

    
simplePassthroughMethods = [
  'ascii'
  'binary'
  'abort'
  'cwd'
  'delete'
  'status'
  'rename'
  'logout'
  'listSafe'
  'list'
  'get'
  'put'
  'append'
  'pwd'
  'cdup'
  'mkdir'
  'rmdir'
  'system'
  'size'
  'lastMod'
  'restart'
]
    

class PromiseFtp
  
  constructor: () ->
    @options = null
    @name = "PromiseFtp"
    @serverMessage = undefined
    @connected = false
    @closedWithError = false
    @errors = []
    
    @client = new FtpClient()
    @client.on 'greeting', (msg) =>
      @serverMessage = msg
    @client.on 'close', (hadError) =>
      @connected = false
      if hadError
        @closedWithError = true
    @client.once 'error', (err) =>
      @errors.push(err)
      
    promisifiedMethods = {}
    
    for name in simplePassthroughMethods
      promisifiedMethods[name] = Promise.promisify(FtpClient.prototype[name], @client)
      @[name] = do (name) => (args...) =>
        if !@connected
          return Promise.reject(new FtpConnectionError("client not currently connected"))
        promisifiedMethods[name](args...)
    promisifiedMethods.site = Promise.promisify(@client.site, @client)
    @site = (args...) =>
      if !@connected
        return Promise.reject(new FtpConnectionError("client not currently connected"))
      promisifiedMethods.site(args...)
      .spread (text, code) =>
        text: text
        code: code


  connect: (options) -> new Promise (resolver, rejector) =>
    doneConnecting = false
    if @connected
      return rejector(new FtpConnectionError("client currently connected to: #{@options.host}"))
    @options = options
    readyListener = () =>
      doneConnecting = true
      @connected = true
      resolver(@serverMessage)
    @client.once 'ready', readyListener
    @client.once 'error', (err) =>
      if !doneConnecting
        @client.removeListener 'ready', readyListener
        rejector(err)
    @client.connect @options
  
  end: () -> new Promise (resolver, rejector) =>
    if !@connected
      return rejector(new FtpConnectionError("client not currently connected"))
    @client.once 'close', (hadError) =>
      resolver(hadError)
    @client.end()
  
  destroy: () -> Promise.try () =>
    if !@connected
      Promise.reject(new FtpConnectionError("client not currently connected"))
    else
      @client.destroy()
      Promise.resolve()

module.exports = PromiseFtp
