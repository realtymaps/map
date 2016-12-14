app = require '../app.coffee'

cleanData = () ->
  name: ''
  type: ''

changeObjectsFactory = (change, {objectsName, parentName}) ->
  objectsName ?= 'objects'

  "#{objectsName}":
    use: false
    change: () ->
      change(@use, {objectsName, parentName})

admin =
  dtColumnRegex: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
  defaults:
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
    schemaOptions: (changeCb) ->
      listing_data:
        db: []
        table: []
        column: []
        photos: changeObjectsFactory(changeCb, {parentName: 'photos'})
      agent_data:
        db: []
        table: []
        column: []

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
app.factory 'rmapsChangeObjectsFactory', changeObjectsFactory
