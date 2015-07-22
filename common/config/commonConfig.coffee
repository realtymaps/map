commonConfig =
  SUPPORT_EMAIL: 'support@realtymaps.com'
  UNEXPECTED_MESSAGE: (troubleshooting) ->
    return "Oops! Something unexpected happened! Please try again in a few minutes. If the problem continues,
            please let us know by emailing #{commonConfig.SUPPORT_EMAIL}, and giving us the following error
            message: "+(if troubleshooting then "<br/><code>#{troubleshooting}</code>" else "")

  map:
    options:
      zoomThresh:
        addressParcel: 18
        price: 15
        clustering: 12
        ordering: 12
        roundOne: 12
        roundNone: 9
  images:
    dimensions:
      profile:
        width: 200
        height: 200


module.exports = commonConfig
