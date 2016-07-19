###
Filters service to get current and set filters
###
app = require '../app.coffee'

app.factory 'rmapsFiltersFactory', () ->

  # query filters
  values =
    propertyStatus: [
      { name: '', value: undefined }
      { name: 'For Sale', value: 'forSale' }
      { name: 'Pending', value: 'pending' }
      { name: 'Sold', value: 'sold' }
      { name: 'Not For Sale', value:'notForSale' }
    ]
    propertyTypes: [
      { name: 'Single Family', value: 'Single Family' }
      { name: 'Condo / Townhome', value: 'Condo / Townhome' }
      { name: 'Lots', value: 'Lots' }
      { name: 'Multi-Family', value: 'Multi-Family' }
    ]
    acresValues: [
      { value: '0.1', name: '.10 acres' }
      { value: '0.2', name: '.20 acres' }
      { value: '0.3', name: '.30 acres' }
      { value: '0.4', name: '.40 acres' }
      { value: '0.5', name: '.50 acres' }
      { value: '0.6', name: '.60 acres' }
      { value: '0.7', name: '.70 acres' }
      { value: '0.8', name: '.80 acres' }
      { value: '0.9', name: '.90 acres' }
      { value: '1.0', name: '1.0 acres' }
    ]
    hasOwner: [
      { value: undefined, name: '' }
      { value: 'true', name: 'yes' }
      { value: 'false', name: 'no' }
    ]
    listedDays: [
      { value: 15, name: '15+' }
      { value: 30, name: '30+' }
      { value: 60, name: '60+' }
      { value: 120, name: '120+'}
      { value: 240, name: '240+'}
      { value: 365, name: '1 year+'}
      { value: 580, name: '~ 1.5 years+'}
      { value: 730, name: '2 years+'}
    ]
    soldRangeValues: [
      { value: '10 day', name: '10 days' }
      { value: '30 day', name: '30 days' }
      { value: '60 day', name: '60 days' }
      { value: '90 day', name: '90 days' }
      { value: '120 day', name: '120 days' }
      { value: '6 month', name: '6 months' }
      { value: '9 month', name: '9 months' }
      { value: '1 year', name: '1 year' }
      { value: '2 year', name: '2 years' }
      { value: '3 year', name: '3 years' }
      { value: 'all', name: 'All of time' }
    ]

  values.soldRange = _.zipObject(_.map(values.soldRangeValues, 'value'), _.map(values.soldRangeValues, 'name'))

  {values}
