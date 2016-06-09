Promise = require 'bluebird'
basePath = '../../backend'
logger = require "#{basePath}/config/logger"
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
shutdown = require '../../backend/config/shutdown'
analyzeValue = require '../../common/utils/util.analyzeValue'


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
      return Promise.reject(exitWithError: false)

    if oldEncryptor.decrypt(sanity) != 'you are using the correct key!'
      logger.error "#{prefix} Neither old nor new key checks out!!!  OH NOES!"
      return Promise.reject(exitWithError: true)

    logger.info "#{prefix} Old encryption key still in use, updating encrypted payloads."
  .then () ->

    tables = require "#{basePath}/config/tables"


    recrypt = (payload) ->
      if !payload?
        return payload
      return newEncryptor.encrypt(oldEncryptor.decrypt(payload))


    dbs = require "#{basePath}/config/dbs"
    dbs.transaction 'main', (transaction) ->
      Promise.try () ->
        logger.info "#{prefix} changing key for sanity check..."
        keystore.setValue('ENCRYPTION_AT_REST', newEncryptor.encrypt('you are using the correct key!'), namespace: 'sanity', transaction: transaction)
      .then () ->
        logger.info "#{prefix} changing key for external accounts..."
        externalAccounts = require '../../backend/services/service.externalAccounts'
        tables.config.externalAccounts(transaction: transaction)
        .select('name')
        .then (externalAccountsList) ->
          Promise.map externalAccountsList, (accountName) ->
            logger.info "#{prefix} ... changing key for account: #{accountName} ..."
            externalAccounts.getAccountInfo(accountName, transaction: transaction, cipherKey: process.env.OLD_ENCRYPTION_AT_REST)
            .then (accountInfo) ->
              externalAccounts.updateAccountInfo(accountInfo, transaction: transaction, cipherKey: process.env.ENCRYPTION_AT_REST)
      .then () ->
        logger.info "#{prefix} DONE!"
.then () ->
  shutdown.exit()
.catch (err) ->
  if err.exitWithError?
    shutdown.exit(error: err.exitWithError)
  else
    logger.error(analyzeValue.getSimpleDetails(err))
    shutdown.exit(error: true)
