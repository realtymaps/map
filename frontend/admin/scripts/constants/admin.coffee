app = require '../app.coffee'
_ = require 'lodash'


cleanData = () ->
  name: ''
  type: ''


# NOTE: One of the most important config definitions right here as it flushes out _.mapValues below
columns =
  listing_data:
    lastModTime: "Update Timestamp"
    mlsListingId: "MLS Listing ID"
    photoId: "Photo ID"
  agent_data:
    lastModTime: "Update Timestamp"

admin =
  defaults:
    columns: columns
    columnRegExes:
      lastModTime: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
      mlsListingId: /.*?mls.*number.*?|.*?listing.*id.*?|.*?sysid.*?|.*?mls.*id.*?/
      photoId: /.*?id.*?/
    base:
      id: null
      name: null
      formal_name: null
      notes: ''
      username: null
      password: null
      url: null
      disclaimer_logo: null
      disclaimer_text: null
      dmca_contact_name: null
      dmca_contact_address: null

    propertySchema:
      listing_data: _.extend({largestPhotoObject: 'Photo'}, _.mapValues columns.listing_data, (v) -> cleanData())
    agentSchema:
      agent_data: _.extend({}, _.mapValues columns.agent_data, (v) -> cleanData())
    otherConfig:
      static_ip: false
      verify_overlap: true
    task:
      active: false

    schemaOptions:
      listing_data:
        db: []
        table: []
        columns: {}
        photos: null # must be created in $scope
      agent_data:
        db: []
        table: []
        columns: {}

    fieldNameMap:
      listing_data: _.extend {
        dbNames: {}
        tableNames: {}
      }, _.mapValues(columns.listing_data, (v) -> {columnNames: {}, columnTypes: {}})
      agent_data: _.extend {
        dbNames: {}
        tableNames: {}
      }, _.mapValues(columns.agent_data, (v) -> {columnNames: {}, columnTypes: {}})
      objects: {}

    # simple tracking for listing_data dropdowns
    formItems:
      listing_data: _.extend {
        db: disabled: false
        table: disabled: false
      }, _.mapValues(columns.listing_data, (v) -> {disabled: false})

      agent_data: _.extend {
        db: disabled: false
        table: disabled: false
      }, _.mapValues(columns.listing_data, (v) -> {disabled: false})

  dataSource:
    lookupThreshold: 50
  ui:
    otherConfig:
      static_ip:
        label: 'Use Static IP Address'
        type: 'checkbox'
      verify_overlap:
        label: 'Verify Data Overlap'
        type: 'checkbox'

app.constant 'rmapsAdminConstants', admin

app.constant 'rmapsCleanData', cleanData
