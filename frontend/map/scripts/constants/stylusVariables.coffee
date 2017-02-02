app = require '../app.coffee'
fs = require 'fs'
loader = require '../../../../common/utils/util.stylusVariableLoader.coffee'

colorPalette = loader fs.readFileSync __dirname + '/../../styles/color_palatte.styl', 'utf8'
colorScheme = loader fs.readFileSync __dirname + '/../../styles/color_scheme.styl', 'utf8'

variables = {}
for key,value of colorScheme
  # check the color palate for an indirect color reference (which is what should happen), but fall back to literal
  # value just in case (and to aid troubleshooting)
  variables[key] = colorPalette[value]||value

app.constant 'rmapsStylusConstants',
  variables

module.exports = variables
