Promise = require 'bluebird'

Encryptor = require './utils/util.encryptor'
oldEncryptor = new Encryptor(cipherKey: process.env.OLD_ENCRYPTION_AT_REST)
newEncryptor = new Encryptor(cipherKey: process.env.ENCRYPTION_AT_REST)

dbs = require './config/dbs'
tables = require './config/tables'
logger = require './config/logger'


recrypt = (payload) ->
  if !payload?
    return payload
  return newEncryptor.encrypt(oldEncryptor.decrypt(payload))


dbs.users.knex.transaction (transaction) ->
  Promise.try () ->
    logger.info "changing key for corelogic task creds..."
    tables.jobQueue.taskConfig(transaction)
    .where(name: 'corelogic')
    .then (rows=[]) ->
      if !rows?.length
        return
      task = rows[0]
      task.data.password = recrypt(task.data.password)
      tables.jobQueue.taskConfig(transaction)
      .where(name: 'corelogic')
      .update(data: task.data)
  .then () ->
    logger.info "changing key for digimaps task creds..."
    tables.jobQueue.taskConfig(transaction)
    .where(name: 'parcel_update')
    .then (rows=[]) ->
      if !rows?.length
        return
      task = rows[0]
      for key, payload of task.data.DIGIMAPS
        task.data.DIGIMAPS[key] = recrypt(payload)
      tables.jobQueue.taskConfig(transaction)
      .where(name: 'parcel_update')
      .update(data: task.data)
  .then () ->
    logger.info "changing key for mls passwords..."
    tables.config.mls(transaction)
    .then (rows=[]) ->
      Promise.map rows, (mls) ->
        logger.info "... changing key for mls: #{mls.id}..."
        mls.password = recrypt(mls.password)
        tables.config.mls(transaction)
        .where(id: mls.id)
        .update(password: mls.password)
  .then () ->
    logger.info "changing key for external accounts..."
    tables.userData.externalAccounts(transaction)
    .then (rows=[]) ->
      Promise.map rows, (account) ->
        logger.info "... changing key for account: #{account.name}..."
        account.username = recrypt(account.username)
        account.password = recrypt(account.password)
        account.api_key = recrypt(account.api_key)
        for key, payload of account.other
          account.other[key] = recrypt(payload)
        tables.userData.externalAccounts(transaction)
        .where(name: account.name)
        .update(account)
  .then () ->
    logger.info "DONE!"
