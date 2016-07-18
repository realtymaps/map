{validators} = require '../util.validation'

image =
  account_image_id:
    transform: validators.integer()
    required: true

imageByUser =
  params: validators.object subValidateSeparate:
    id: validators.integer()
  query: validators.object isEmptyProtect: true
  body: validators.object isEmptyProtect: true

module.exports = {
  image
  imageByUser
}
