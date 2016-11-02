_ = require 'lodash'
mod = require '../module.coffee'

statusData =
  pending: 'pending'
  forSale: 'for sale'
  discontinued: 'discontinued'

statusFilter =
  sold: 'sold'

agentStatus =
  active: 'active'
  inactive: 'inactive'

propertyType = {
  'Single Family',
  'Condo / Townhome',
  'Multi-Family'
  'Land / Lot',
  'Commercial'
  'Industrial'
  'Agricultural'
  'Recreational / Seasonal'
}

datetimeFormats = [
  'none'
  'YYYY-MM-DD'
  'YYYYMMDD'
  'MMDDYYYY'
  'YYYY-MM-DD[T]HH:mm:ss'
  'MMMM Do, YYYY'
  'HH:mm:ss'
]


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
    agent:
      base:'Base'
      unassigned: 'Unassigned'
  county:
    tax:
      base: 'Base'
      unassigned: 'Unassigned'
      hidden: 'Hidden'
      general: 'General'
      taxes: 'Taxes & Assessments'
      lot: 'Lot & Legal'
      location: 'Location'
      building: 'Building'
      owner: 'Owner'
      deed: 'Deed'
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

mod.constant 'rmapsParcelEnums', {
  status: _.extend({}, statusData, statusFilter)
  statusData
  agentStatus
  categories
  address
  propertyType
  datetimeFormats
  lookupOptions:
    status: _.values(statusData)
    property_type: _.values(propertyType)
    agent_status: _.values(agentStatus)
}
