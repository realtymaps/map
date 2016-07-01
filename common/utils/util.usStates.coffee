_ = require 'lodash'

all = [
  { id: 1, code: 'AL', name: 'Alabama' }
  { id: 2, code: 'AK', name: 'Alaska' }
  { id: 3, code: 'AZ', name: 'Arizona' }
  { id: 4, code: 'AR', name: 'Arkansas' }
  { id: 5, code: 'CA', name: 'California' }
  { id: 6, code: 'CO', name: 'Colorado' }
  { id: 7, code: 'CT', name: 'Connecticut' }
  { id: 8, code: 'DE', name: 'Delaware' }
  { id: 9, code: 'DC', name: 'District of Columbia' }
  { id: 10, code: 'FL', name: 'Florida' }
  { id: 11, code: 'GA', name: 'Georgia' }
  { id: 12, code: 'HI', name: 'Hawaii' }
  { id: 13, code: 'ID', name: 'Idaho' }
  { id: 14, code: 'IL', name: 'Illinois' }
  { id: 15, code: 'IN', name: 'Indiana' }
  { id: 16, code: 'IA', name: 'Iowa' }
  { id: 17, code: 'KS', name: 'Kansas' }
  { id: 18, code: 'KY', name: 'Kentucky' }
  { id: 19, code: 'LA', name: 'Louisiana' }
  { id: 20, code: 'ME', name: 'Maine' }
  { id: 21, code: 'MD', name: 'Maryland' }
  { id: 22, code: 'MA', name: 'Massachusetts' }
  { id: 23, code: 'MI', name: 'Michigan' }
  { id: 24, code: 'MN', name: 'Minnesota' }
  { id: 25, code: 'MS', name: 'Mississippi' }
  { id: 26, code: 'MO', name: 'Missouri' }
  { id: 27, code: 'MT', name: 'Montana' }
  { id: 28, code: 'NE', name: 'Nebraska' }
  { id: 29, code: 'NV', name: 'Nevada' }
  { id: 30, code: 'NH', name: 'New Hampshire' }
  { id: 31, code: 'NJ', name: 'New Jersey' }
  { id: 32, code: 'NM', name: 'New Mexico' }
  { id: 33, code: 'NY', name: 'New York' }
  { id: 34, code: 'NC', name: 'North Carolina' }
  { id: 35, code: 'ND', name: 'North Dakota' }
  { id: 36, code: 'OH', name: 'Ohio' }
  { id: 37, code: 'OK', name: 'Oklahoma' }
  { id: 38, code: 'OR', name: 'Oregon' }
  { id: 39, code: 'PA', name: 'Pennsylvania' }
  { id: 40, code: 'RI', name: 'Rhode Island' }
  { id: 41, code: 'SC', name: 'South Carolina' }
  { id: 42, code: 'SD', name: 'South Dakota' }
  { id: 43, code: 'TN', name: 'Tennessee' }
  { id: 44, code: 'TX', name: 'Texas' }
  { id: 45, code: 'UT', name: 'Utah' }
  { id: 46, code: 'VT', name: 'Vermont' }
  { id: 47, code: 'VA', name: 'Virginia' }
  { id: 48, code: 'WA', name: 'Washington' }
  { id: 49, code: 'WV', name: 'West Virginia' }
  { id: 50, code: 'WI', name: 'Wisconsin' }
  { id: 51, code: 'WY', name: 'Wyoming' }
]

# TODO: remove all references to state ids, instead just use the 2-letter code
byId = _.indexBy(all, 'id')
byName = _.indexBy all, (row) -> row.name?.toUpperCase()
byCode = _.indexBy(all, 'code')


#
# Export for Require statements
#
module.exports = {
  all
  getById: (id) -> byId[id]
  getByName: (name) -> byName[name?.toUpperCase()]
  getByCode: (code) -> byCode[code?.toUpperCase()]
}

#
# Expose as an Angular Service on the Common Utils module
#
if window?.angular?
  commonUtilsModule = require './angularModule.coffee'
  commonUtilsModule.factory 'rmapsUsStates', () ->
    return module.exports
