app = require '../app.coffee'

_queryTemplate = "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"

mls =
  queryTemplate: _queryTemplate
  dtColumnRegex: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
  defaults:
    base:
      id: null
      name: null
      notes: ""
      active: false
      username: null
      password: null
      url: null
      main_property_data: {"queryTemplate": _queryTemplate}
    config:
      static_id: 1


app.constant 'mlsConstants', mls
