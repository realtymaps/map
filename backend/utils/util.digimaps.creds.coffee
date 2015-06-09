db = require('../config/dbs').users
{singleRow} = require '../utils/util.sql.helpers'
config = require '../config/config'
encryptor = null
logger = require '../config/logger'
Promise = require 'bluebird'

try
    encryptor = new (require '../utils/util.encryptor')(cipherKey: config.ENCRYPTION_AT_REST)
catch err
    if process.env.CIRCLECI
        return logger.warn "CIRCLECI: #{err}"
    throw err


module.exports = Promise.try ->    
    singleRow(db.knex.select().from('jq_task_config').where(name:'parcel_update'))
    .then (row) ->
        # logger.debug row
        for k, val of row.data.DIGIMAPS
            row.data.DIGIMAPS[k] = encryptor.decrypt(val)
        row.data.DIGIMAPS
