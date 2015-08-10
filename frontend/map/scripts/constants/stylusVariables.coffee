app = require '../app.coffee'

loader = require '../../../../backend/utils/util.stylusVariableLoader.coffee'
colorPalate = loader require '../../styles/color_palate.styl'
colorScheme = loader require '../../styles/color_scheme.styl'

variables = {}
for key,value of colorScheme
  # check the color palate for an indirect color reference (which is what should happen), but fall back to literal
  # value just in case (and to aid troubleshooting)
  variables[key] = colorPalate[value]||value

app.constant 'rmapsstylusVariables',
  variables
