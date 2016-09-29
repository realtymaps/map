{validators} = require '../util.validation'

transforms =
    nesw:
      transform: validators.neSwBounds
      required: false
    fipscode:
      transform: validators.string(minLength:1)
      required: true
    limit: validators.integer()
    start_rm_property_id: validators.string(minLength: 5)
    api_key:
      transform: [
        validators.string(minLength: 36)
        validators.string(maxLength: 36)
      ]
      required: true

module.exports = transforms
