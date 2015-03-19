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
        price: 16
        clustering: 17
        ordering: 17
        roundOne: 13
        roundNone: 9

module.exports = commonConfig
