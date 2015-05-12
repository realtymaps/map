app = require '../app.coffee'

colorPalate = require '!!../../../backend/utils/util.stylusVariableLoader.coffee!../../styles/color_palate.styl'
colorScheme = require '!!../../../backend/utils/util.stylusVariableLoader.coffee!../../styles/color_scheme.styl'

variables = {}
for key,value of colorScheme
  # check the color palate for an indirect color reference (which is what should happen), but fall back to literal
  # value just in case (and to aid troubleshooting)
  variables[key] = colorPalate[value]||value
  
app.constant 'stylusVariables'.ourNs(),
  variables
