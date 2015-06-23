app = require '../app.coffee'

mls =
  queryTemplate: "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"
  dtColumnRegex: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/

app.constant 'mlsConstants', mls
