###
Filters service to get current and set filters
###
app = require '../app.coffee'

module.exports =
  app.factory 'Filters'.ourNs(), [ () =>

    # query filters 
    values:
      propertyStatus: [
        { label: "For Sale", value: "forSale" }
        { label: "Pending", value: "pending" }
        { label: "Sold", value: "sold" }
        { label: "Not For Sale", value:"notForSale" }
      ]
      beds: [
        { value: null, name: "clear" }
        { value: "1", name: "1+" }
        { value: "2", name: "2+" }
        { value: "3", name: "3+" }
        { value: "4", name: "4+" }
        { value: "5", name: "5+" }
        { value: "6", name: "6+" }
      ]
      baths: [
        { value: null, name: "clear" }
        { value: "1", name: "1+" }
        { value: "2", name: "2+" }
        { value: "3", name: "3+" }
        { value: "4", name: "4+" }
        { value: "5", name: "5+" }
        { value: "6", name: "6+" }
      ]
      acresValues: [
        { value: null, name: "clear" }
        { value: "0.1", name: ".10 acres" }
        { value: "0.2", name: ".20 acres" }
        { value: "0.3", name: ".30 acres" }
        { value: "0.4", name: ".40 acres" }
        { value: "0.5", name: ".50 acres" }
        { value: "0.6", name: ".60 acres" }
        { value: "0.7", name: ".70 acres" }
        { value: "0.8", name: ".80 acres" }
        { value: "0.9", name: ".90 acres" }
        { value: "1.0", name: "1.0 acres" }
      ]
      hasOwner: [
        { value: null, name: "clear" }
        { value: 'true', name: "yes" }
        { value: 'false', name: "no" }
      ]
      listedDays: [
        { value: null, name: "clear" }
        { value: "15", name: "15+" }
        { value: "30", name: "30+" }
        { value: "60", name: "60+" }
        { value: "120", name: "120+"}
        { value: "240", name: "240+"}
        { value: "365", name: "1 year+"}
        { value: "580", name: "~ 1.5 years+"}
        { value: "730", name: "2 years+"}
      ]

    #TODO - add function to warn when Max and Min values are swapped.
  ]
