app = require '../app.coffee'

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
      listing_data: {}
    otherConfig:
      static_ip: false
      verify_overlap: true
    task:
      active: false
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
