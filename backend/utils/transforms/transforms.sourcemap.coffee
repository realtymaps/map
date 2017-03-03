{validators} = require '../util.validation'

get =
  params: validators.object subValidateSeparate:
    fileName: validators.string(minLength:2)
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true

module.exports = {
  get
}
