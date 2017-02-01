app = require '../app.coffee'
fs = require 'fs'
loader = require '../../../../common/utils/util.stylusVariableLoader.coffee'

colorPalette = loader fs.readFileSync __dirname + '/../../styles/color_palatte.styl', 'utf8'

app?.constant?('rmapsStylusColorPalette', colorPalette)

module.exports = colorPalette
