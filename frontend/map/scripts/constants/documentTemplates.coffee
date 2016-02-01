app = require '../app.coffee'

app.constant 'rmapsDocumentTemplateConstants',
  'letter.expired': require '../../../../common/documentTemplates/document.letter.expired.coffee'
  'letter.preforeclosure': require '../../../../common/documentTemplates/document.letter.preforeclosure.coffee'
  'letter.prospecting-nobroker': require '../../../../common/documentTemplates/document.letter.prospecting-nobroker.coffee'
  'letter.prospecting': require '../../../../common/documentTemplates/document.letter.prospecting.coffee'
