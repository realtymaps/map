_ = require('lodash')

status =
  notForSale: 'not for sale'
  sold: 'recently sold'
  pending: 'pending'
  forSale: 'for sale'

subStatus =
  discontinued: 'discontinued'
  auction: 'auction'

categories =
  base: 'Base'
  unassigned: 'Unassigned'
  hidden: 'Hidden'
  general: 'General'
  details: 'Details'
  listing: 'Listing'
  building: 'Building'
  lot: 'Lot'
  location: 'Location & Schools'
  dimensions: 'Room Dimensions'
  restrictions: 'Taxes, Fees, and Restrictions'
  contacts: 'Listing Contacts (realtor only)'
  realtor: 'Listing Details (realtor only)'
  sale: 'Sale Details (realtor only)'

address =
  streetNum: 'Street Number'
  streetName: 'Street Name'
  city: 'City'
  state: 'State or Province'
  zip: 'Postal Code'
  zip9: 'Postal Code + 4'
  streetDirPrefix: 'Street Dir Prefix'
  streetDirSuffix: 'Street Dir Suffix'
  streetNumModifier: 'Street Number Modifier'
  streetFull: 'Full Street'

module.exports =
  status: status
  subStatus: _.extend(subStatus, status)
  categories: categories
  address: address
