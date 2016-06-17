app = require '../app.coffee'
module.exports = app

app.controller 'rmapsMailPricingTableCtrl', (
  $rootScope,
  $scope,
  $log,
  rmapsPricingService,
  rmapsMainOptions
) ->

  pricingData = {}

  $log = $log.spawn 'rmapsMailPricingTableCtrl'

  $scope.getPricing = ({pages}) ->
    price = "N/A"

    # color price...
    if $scope.wizard.mail.campaign.options.color
      price = rmapsMainOptions.mail.getPrice(
        firstPage: pricingData.colorPage
        extraPage: pricingData.colorExtra,
        pages: pages,
        recipientCount: $scope.wizard.mail.campaign.recipients.length
      )

    # bnw price...
    else
      price = rmapsMainOptions.mail.getPrice(
        firstPage: pricingData.bnwPage
        extraPage: pricingData.bnwExtra,
        pages: pages,
        recipientCount: $scope.wizard.mail.campaign.recipients.length
      )

    price


  rmapsPricingService.getMailPricings()
  .then (data) ->
    pricingData = data