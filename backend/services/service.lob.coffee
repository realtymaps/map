config = require '../config/config'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
logger = require '../config/logger'
_ = require 'lodash'


testLob = new LobFactory(config.LOB.TEST_API_KEY)
testLob.rm_type = 'test'
promisify.lob(testLob)
liveLob = new LobFactory(config.LOB.LIVE_API_KEY)
liveLob.rm_type = 'live'
promisify.lob(liveLob)


rawLetterContent = """
<html>
<head>
<link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>
<title>Lob.com Sample Letter Template = true</title>
<style>
  *, *:before, *:after {
    -webkit-box-sizing: border-box;
    -moz-box-sizing: border-box;
    box-sizing: border-box;
  }

  body {
    width: 8.5in;
    height: 11in;
    margin: 0;
    padding: 0;
  }

  .page {
    page-break-after: always;
  }

  .page-content {
    position: relative;
    width: 8.125in;
    height: 10.625in;
    left: 0.1875in;
    top: 0.1875in;
    background-color: rgba(0,0,0,0.2);
  }

  .text {
    position: relative;
    left: 20px;
    top: 20px;
    width: 6in;
    font-family: 'Open Sans';
    font-size: 30px;
  }

  #return-address-window {
    position: absolute;
    left: .625in;
    top: .5in;
    width: 3.25in;
    height: .875in;
    background-color: rgba(255,0,0,0.5);
  }

  #return-address-text {
    position: absolute;
    left: .07in;
    top: .34in;
    width: 2.05in;
    height: .44in;
    background-color: white;
    font-size: .11in;
  }

  #recipient-address-window {
    position: absolute;
    left: .625in;
    top: 1.75in;
    width: 4in;
    height: 1in;
    background-color: rgba(255,0,0,0.5);
  }

  #recipient-address-text {
    position: absolute;
    left: .07in;
    top: .05in;
    width: 2.92in;
    height: .9in;
    background-color: white;
  }

</style>
</head>

<body>
  <div class="page">
    <div class="page-content">
      <div class="text" style="top: 3in">
        The grey box is the safe area. Do not put text outside this box. If you are using the data argument, you can add variables like this: {{variable_name}}.
      </div>
    </div>
    <div id="return-address-window">
      <div id="return-address-text">
        The Return Address will be printed here. The red area will be visible through the envelope window.
      </div>
    </div>
    <div id="recipient-address-window">
      <div id="recipient-address-text">
        The Recipient's Address will be printed here. The red area will be visible through the envelope window.
      </div>
    </div>
  </div>
  <div class="page">
    <div class="page-content">
      <div class="text">
        This is a second page.
      </div>
    </div>
  </div>
</body>

</html>
"""


filterLobResponseErrors = (res) ->
  if 'errors' not of res
    return
  errorList = _.cloneDeep res.errors
  anError = errorList.pop()
  msg = "#{anError.message}"
  while anError = errorList.pop()
    msg = "#{msg}, #{anError.message}"
  msg = "#{msg}, Placeholder Msg"
  throw new Error(msg) # throw it up for Express to handle

createNewLobObject = (Lob, userId, data) -> Promise.try () ->
  Lob.addresses.createAsync(data.recipient)
  .then (lobResponse) ->
    filterLobResponseErrors(lobResponse)
    lobResponse
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} Lob.addresses: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse.id

sendJob = (Lob, userId, data) -> Promise.try () ->
  createNewLobObject(Lob, userId, data)
  .then (address) ->
    Lob.letters.createAsync
      description: data.description
      #to: address.id
      to: data.recipient
      from: data.sender
      file: data.content
      #file: rawLetterContent
      #data: data.macros
      data: {'name': 'Justin'}
      color: false
  .then (lobResponse) ->
    filterLobResponseErrors(lobResponse)
    lobResponse
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} Lob.letters: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse

module.exports =
  getPriceQuote: (userId, data) -> Promise.try () ->
    sendJob(testLob, userId, data)
    .then (lobResponse) ->
      lobResponse.price
  sendSnailMail: (userId, templateId, data) -> sendJob(liveLob, userId, data)
