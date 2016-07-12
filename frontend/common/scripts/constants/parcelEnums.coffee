_ = require 'lodash'
mod = require '../module.coffee'

statusUniversal =
  notForSale: 'not for sale'
  pending: 'pending'
  forSale: 'for sale'

statusFilter =
  sold: 'sold'

subStatus =
  discontinued: 'discontinued'
  auction: 'auction'

propertyType = {
  'Single Family',
  'Condo / Townhome',
  'Multi-Family'
  'Land / Lot',
  'Commercial'
  'Industrial'
  'Agricultural'
}

categories =
  mls:
    listing:
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
  county:
    tax:
      base: 'Base'
      unassigned: 'Unassigned'
      hidden: 'Hidden'
      general: 'General'
      details: 'Details'
      sale: 'Sale History'
      taxes: 'Taxes & Assessments'
      lot: 'Lot & Location'
      building: 'Building'
      owner: 'Owner'
      deed: 'Deed'
      mortgage: 'Mortgage'
    deed:
      base: 'Base'
      unassigned: 'Unassigned'
      hidden: 'Hidden'
      owner: 'Owner'
      deed: 'Deed'
    mortgage:
      base: 'Base'
      unassigned: 'Unassigned'
      hidden: 'Hidden'
      mortgage: 'Mortgage'


address =
  streetNum: 'Street Number'
  streetName: 'Street Name'
  city: 'City'
  state: 'State or Province'
  zip: 'Postal Code'
  zip9: 'Postal Code + 4'
  streetDirPrefix: 'Street Dir Prefix'
  streetDirSuffix: 'Street Dir Suffix'
  streetSuffix: 'Street Suffix',
  streetNumSuffix: 'Street Number Suffix'
  streetFull: 'Full Street'
  unitNum: 'Unit Number'
  showStreetInfo: 'Show Street Info'


statusFull = _.extend(statusUniversal, statusFilter)
subStatusFull = _.extend(statusUniversal, statusFilter, subStatus)
statusData = statusUniversal

mod.constant 'rmapsParcelEnums', {
  status: statusFull
  subStatus: subStatusFull
  statusData
  categories
  address
  propertyType
  lookupOptions:
    status: _.values(statusData)
    substatus: _.values(subStatusFull)
    property_type: _.values(propertyType)
}
