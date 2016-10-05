Promise = require 'bluebird'
profileSvc = require '../services/service.profiles'
errors = require '../utils/errors/util.errors.properties'
logger = require('../config/logger').spawn('service:properties:save')
tables = require '../config/tables'

###
  NOTE: everything in here is profile centric
###

_favoritesPromise = (profile) ->
  tables.user.profile()
  .select('favorites')
  .where id: profile.id

_pinsPromise = (profile) ->
  tables.user.project()
  .select('pins')
  .where id: profile.project_id

###
  UpdateRaw function for modifying pins or favorites json atomically.

 - `table`          dbFn from tables {function/object}
 - `column`         column name of interest (pins, favorites){string}.
 - `toUpdate`       An entity for when we are adding a json field {object}.
 - `rm_property_id` rm_property_id as {string}.
 - `id`             table of interest id for the where clause update restriction {int}.

  Returns knex promise / query.
###
_updateRaw = ({table, column, toUpdate, rm_property_id, id}) ->
  raw = if toUpdate?
    table().raw('?? || ?', [column, "#{rm_property_id}": toUpdate])
  else #delete
    table().raw('?? - ?',  [column, rm_property_id])

  table()
  .where {id}
  .update "#{column}": raw

_pin = ({rm_property_id, type, doAdd}) ->
  profile = profileSvc.getCurrentSessionProfile()
  logger.debug "#@@@@@@@@@@@@@@@@ type: #{type}@@@@@@@@@@@@@@@@@@@@@"
  #get what is in the db to make sure we are synced
  _pinsPromise profile
  .then ([row]) ->
    logger.debug "#@@@@@@@@@@@@@@@@ in promise type: #{type}@@@@@@@@@@@@@@@@@@@@@"
    if (!row?.pins?[rm_property_id]? && type == 'pin') || (row?.pins?[rm_property_id]? && type == 'unPin')
      logger.debug "#@@@@@@@@@@@@@@@@ can do type: #{type}@@@@@@@@@@@@@@@@@@@@@"
      logger.debug "prior pins length: #{Object.keys(row.pins).length}"

      if doAdd
        toUpdate = {rm_property_id, isPinned: true}

      logger.debug "#@@@@@@@@@@@@@@@@ update type: #{type}@@@@@@@@@@@@@@@@@@@@@"

      _updateRaw { # {table, column, toUpdate, rm_property_id, id}
        table: tables.user.project
        column: 'pins'
        rm_property_id
        toUpdate
        id: profile.project_id
      }
      .then () ->
        logger.debug "#@@@@@@@@@@@@@@@@ eventsQueue type: #{type}@@@@@@@@@@@@@@@@@@@@@"
        tables.user.eventsQueue()
        .insert {
          auth_user_id: profile.auth_user_id
          project_id: profile.project_id
          type: 'propertySaved'
          sub_type: type
          options: {
            rm_property_id
          }
        }

_fave = ({rm_property_id, type, doAdd}) ->
  profile = profileSvc.getCurrentSessionProfile()

  #get what is in the db to make sure we are synced
  _favoritesPromise profile
  .then ([row]) ->
    if (!row?.favorites?[rm_property_id]? && type == 'favorite') || (row?.favorites?[rm_property_id]? && type == 'unFavorite')
      logger.debug "prior favorites length: #{Object.keys(row.favorites).length}"

      if doAdd
        toUpdate = {rm_property_id, isFavorite: true}

      _updateRaw { # {table, column, toUpdate, rm_property_id, id}
        table: tables.user.profile
        column: 'favorites'
        rm_property_id
        toUpdate
        id: profile.id
      }
      .then () ->
        tables.user.eventsQueue()
        .insert {
          auth_user_id: profile.auth_user_id
          project_id: profile.project_id
          type: 'propertySaved'
          sub_type: type
          options: {
            rm_property_id
          }
        }

save = ({type, rm_property_id}) ->
  profile = profileSvc.getCurrentSessionProfile()
  switch type
    when 'pin'
      logger.debug "pinning #{rm_property_id} for profile id: #{profile.id}"
      _pin {type, rm_property_id, doAdd: true}
    when 'unPin'
      logger.debug "unPinning #{rm_property_id} for profile id: #{profile.id}"
      _pin {type, rm_property_id, doAdd: false}
    when 'favorite'
      logger.debug "favorite #{rm_property_id} for profile id: #{profile.id}"
      _fave {type, rm_property_id, doAdd: true}
    when 'unFavorite'
      logger.debug "unFavorite #{rm_property_id} for profile id: #{profile.id}"
      _fave {type, rm_property_id, doAdd: false}
    else
      throw new errors.InvalidSaveType "Unknown save type action."

  # enqueue to user_events_transient

getAll = () ->
  profile = profileSvc.getCurrentSessionProfile()

  Promise.join _pinsPromise(profile), _favoritesPromise(profile), ([{pins}], [{favorites}]) ->
    { pins, favorites }


module.exports = {
  save
  getAll
}
