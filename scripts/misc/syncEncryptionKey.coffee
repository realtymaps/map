Promise = require 'bluebird'
basePath = '../../backend'
logger = require "#{basePath}/config/logger"
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"


Promise.try () ->
  prefix = "ENCRYPTION_AT_REST sync:"
  
  # bail early if there's no old key
  if !process.env.OLD_ENCRYPTION_AT_REST
    logger.info "#{prefix} No old encryption key detected."
    return


  # check to see if we need to do an update
  keystore = require "#{basePath}/services/service.keystore"
  Encryptor = require "#{basePath}/utils/util.encryptor"
  newEncryptor = new Encryptor(cipherKey: process.env.ENCRYPTION_AT_REST)
  oldEncryptor = new Encryptor(cipherKey: process.env.OLD_ENCRYPTION_AT_REST)
  
  keystore.getValue('ENCRYPTION_AT_REST', namespace: 'sanity')
  .then (sanity) ->
    if newEncryptor.decrypt(sanity) == 'you are using the correct key!'
      logger.warn "#{prefix} Old encryption key detected, but new key is already in use."
      return Promise.reject(exit: 0)
  
    if oldEncryptor.decrypt(sanity) != 'you are using the correct key!'
      logger.error "#{prefix} Neither old nor new key checks out!!!  OH NOES!"
      return Promise.reject(exit: 1)
      
    logger.info "#{prefix} Old encryption key still in use, updating encrypted payloads."
  .then () ->
    
    tables = require "#{basePath}/config/tables"
  
    
    recrypt = (payload) ->
      if !payload?
        return payload
      return newEncryptor.encrypt(oldEncryptor.decrypt(payload))
  
  
    dbs = require "#{basePath}/config/dbs"
    dbs.get('main').transaction (transaction) ->
      Promise.try () ->
        logger.info "#{prefix} changing key for sanity check..."
        keystore.setValue('ENCRYPTION_AT_REST', newEncryptor.encrypt('you are using the correct key!'), namespace: 'sanity', transaction: transaction)
      .then () ->
        logger.info "#{prefix} changing key for corelogic task creds..."
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
        logger.info "#{prefix} changing key for digimaps task creds..."
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
          .update(data: sqlHelpers.safeJsonArray(task.data))
      .then () ->
        logger.info "#{prefix} changing key for mls passwords..."
        tables.config.mls(transaction)
        .then (rows=[]) ->
          Promise.map rows, (mls) ->
            logger.info "#{prefix} ... changing key for mls: #{mls.id}..."
            mls.password = recrypt(mls.password)
            tables.config.mls(transaction)
            .where(id: mls.id)
            .update(password: mls.password)
      .then () ->
        logger.info "#{prefix} changing key for external accounts..."
        tables.config.externalAccounts(transaction)
        .then (rows=[]) ->
          Promise.map rows, (account) ->
            logger.info "#{prefix} ... changing key for account: #{account.name}..."
            account.username = recrypt(account.username)
            account.password = recrypt(account.password)
            account.api_key = recrypt(account.api_key)
            for key, payload of account.other
              account.other[key] = recrypt(payload)
            account.other = sqlHelpers.safeJsonArray(account.other)
            tables.config.externalAccounts(transaction)
            .where(name: account.name)
            .update(account)
      .then () ->
        logger.info "#{prefix} DONE!"
    .finally () ->
      dbs.shutdown()
.then () ->
  process.exit(0)
.catch (err) ->
  if err.exit?
    process.exit(err.exit)
  else
    logger.error(err.stack||err)
    process.exit(1)
