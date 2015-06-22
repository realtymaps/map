app = require '../app.coffee'

mls =
  queryTemplate: "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"
  queryTemplateInet: "[(__MODIFIED_TIMESTAMP_FIELD___=]YYYY-MM-DD[T]HH:mm:ss[+),(__ALLOW_INTERNET_FIELD__=1)]"
  dtColumnRegex: /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/

app.constant 'mlsConstants', mls
