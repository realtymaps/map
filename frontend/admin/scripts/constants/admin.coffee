app = require '../app.coffee'

cleanData = () ->
  name: ''
  type: ''


admin =
  defaults:
    columns: [
      'lastModTime'
      'mlsListingId'
    ]
    columnRegExes:
      lastModTime: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
      mlsListingId: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
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
      listing_data: {
        largestPhotoObject: 'Photo'
        mlsListingId: cleanData()
        field: ''
        field_type: ''
      }
    agentSchema:
      agent_data: {}
    otherConfig:
      static_ip: false
      verify_overlap: true
    task:
      active: false

    schemaOptions:
      listing_data:
        db: []
        table: []
        column: []
        photos: null # must be created in $scope
      agent_data:
        db: []
        table: []
        column: []

    fieldNameMap:
      listing_data:
        dbNames: {}
        tableNames: {}
        lastModTime:
          columnNames: {}
          columnTypes: {}
        mlsListingId:
          columnNames: {}
          columnTypes: {}
        # objects: {}
      agent_data:
        dbNames: {}
        tableNames: {}
        lastModTime:
          columnNames: {}
          columnTypes: {}
      objects: {}

    # simple tracking for listing_data dropdowns
    formItems:
      listing_data:
        db: disabled: false
        table: disabled: false
        lastModTime: disabled: false
        mlsListingId: false

      agent_data:
        db: disabled: false
        table: disabled: false
        lastModTime: disabled: false
        mlsListingId: false

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

app.factory 'rmapsCleanData', cleanData
