db = require('../config/dbs').users
_tableName = 'digimaps_parcel_imports'
{singleRow} = require '../utils/util.sql.helpers'
config = require '../config/config'
encryptor = null
logger = require '../config/logger'

try
    encryptor = new (require '../utils/util.encryptor')(cipherKey: config.ENCRYPTION_AT_REST)
catch err
    if process.env.CIRCLECI
        return logger.warn "CIRCLECI: #{err}"
    throw err

logger = require '../config/logger'

_get = ->
    db.knex(_tableName).select()

_insert = (obj) -> db.knex(_tableName).insert(obj)

module.exports =
    get: _get
    insert: _insert
    getImported: ->
        q = _get().whereNotNull('imported_time')
        q.toString()
        logger.debug q
        q

    getCredentials: ->
        singleRow(db.knex.select().from('jq_task_config').where(name:'parcel_update'))
        .then (row) ->
            # logger.debug row
            for k, val of row.data.DIGIMAPS
                row.data.DIGIMAPS[k] = encryptor.decrypt(val)
            row.data.DIGIMAPS
