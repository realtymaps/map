###global _:true###
app = require '../app.coffee'

app.service 'rmapsMailRecipientService', (rmapsPropertiesService) ->

  savedProperties = null
  property_ids = null

  updatePropertyIds = (maybeParcel) ->
    savedProperties = rmapsPropertiesService.getSavedProperties()

    if maybeParcel?
      property_ids = [maybeParcel.rm_property_id]
    else
      property_ids = _.keys savedProperties


  updatePropertyIds: updatePropertyIds
  getPropertyIds: () -> return property_ids
