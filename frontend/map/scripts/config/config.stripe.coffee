app = require '../app.coffee'

app.config (stripeProvider) ->
  stripeProvider.setPublishableKey 'pk_test_6pRNASCoBOKtIshFeQd4XMUh'
