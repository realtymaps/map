{validators} = require '../util.validation'

getAll =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    state: validators.string(minLength:2, maxLength:2)

getAllMlsCodes =
  params: validators.object isEmptyProtect: true
  query: validators.object isEmptyProtect: true
  body: validators.object subValidateSeparate:
    state: validators.string(minLength:2)
    mls: validators.string(minLength:2)
    county: validators.string(minLength:2)
    fips_code: validators.string(minLength:4)
    id: validators.integer()


module.exports = {
  getAll
  getAllMlsCodes
}
