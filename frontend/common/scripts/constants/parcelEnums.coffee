_ = require 'lodash'
mod = require '../module.coffee'

status =
  notForSale: 'not for sale'
  sold: 'recently sold'
  pending: 'pending'
  forSale: 'for sale'

subStatus =
  discontinued: 'discontinued'
  auction: 'auction'

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
      deed: 'Deed & Mortgage'
    deed:
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
      deed: 'Deed & Mortgage'


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

mod.constant 'rmapsParcelEnums',
  status: status
  subStatus: _.extend(subStatus, status)
  categories: categories
  address: address
