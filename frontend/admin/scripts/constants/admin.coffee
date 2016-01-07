app = require '../app.coffee'

_queryTemplate = '[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]'

admin =
  queryTemplate: _queryTemplate
  dtColumnRegex: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
  defaults:
    base:
      id: null
      name: null
      notes: ''
      username: null
      password: null
      url: null
    propertySchema:
      listing_data: {'queryTemplate': _queryTemplate}
    otherConfig:
      static_ip: false
    task:
      active: false
  dataSource:
    lookupThreshold: 50
  ui:
    otherConfig:
      static_ip:
        label: 'Use Static IP Address'
        type: 'checkbox'

app.constant 'adminConstants', admin
