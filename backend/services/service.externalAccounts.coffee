tables = require '../config/tables'
{expectSingleRow} = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
require '../config/promisify'
memoize = require 'memoizee'
Encryptor = require '../utils/util.encryptor'
config = require '../config/config'
# coffeelint: disable=check_scope
logger = require('../config/logger').spawn('service:externalAccounts')
# coffeelint: enable=check_scope
JSON5 = require('json5')


encryptors = {}
_getEncryptor = (cipherKey) ->
  if !encryptors[cipherKey]?
    encryptors[cipherKey] = new Encryptor(cipherKey: cipherKey)
  return encryptors[cipherKey]

_encrypt = (sourceObj, destObj, fieldName, cipherKey) ->
  plainText = sourceObj[fieldName]
  if plainText == undefined
    return
  destObj[fieldName] = if plainText == null then null else _getEncryptor(cipherKey).encrypt(plainText)

_decrypt = (sourceObj, destObj, fieldName, cipherKey) ->
  cipherText = sourceObj[fieldName]
  if cipherText == undefined
    return
  destObj[fieldName] = if cipherText == null then null else _getEncryptor(cipherKey).decrypt(cipherText)

_transform = (fieldTransform, cipherKey, accountInfo) ->
  cipherKey ?= config.ENCRYPTION_AT_REST
  if !cipherKey
    return accountInfo
  result =
    name: accountInfo.name
    environment: accountInfo.environment
  fieldTransform(accountInfo, result, 'username', cipherKey)
  fieldTransform(accountInfo, result, 'password', cipherKey)
  fieldTransform(accountInfo, result, 'api_key', cipherKey)
  fieldTransform(accountInfo, result, 'url', cipherKey)
  if !accountInfo.other?
    result.other = null
  else
    result.other = {}
    for key of accountInfo.other
      fieldTransform(accountInfo.other, result.other, key, cipherKey)
  return result

_handleAccountInfoTypes = (accountInfo) ->
  if typeof(accountInfo) == 'string'
    accountInfo = JSON5.parse(accountInfo)
  accountInfo

_logResult = (opts, result) ->
  if opts.logOnly
    return console.log(JSON.stringify(result,null,2))
  result

getAccountInfo = (name, opts={}) -> Promise.try () ->
  environment = opts.environment ? config.ENV
  tables.config.externalAccounts(transaction: opts.transaction)
  .where(name: name)
  .where () ->
    this.where(environment: environment)
    .orWhereNull('environment')
  .orderBy('environment')
  .then (accountInfo) ->
    expectSingleRow(accountInfo, {quiet: opts.quiet})
  .then (accountInfo) ->
    _transform(_decrypt, opts.cipherKey, accountInfo)
  .then (decryptedInfo) ->
    _logResult(opts, decryptedInfo)

insertAccountInfo = (accountInfo, opts={}) -> Promise.try () ->
  accountInfo = _handleAccountInfoTypes(accountInfo)
  query = tables.config.externalAccounts(transaction: opts.transaction)
  .insert(_transform(_encrypt, opts.cipherKey, accountInfo))
  if opts.logOnly
    return console.log(query.toString())
  console.log "insertAccountInfo query:\n#{query.toString()}"
  query

updateAccountInfo = (accountInfo, opts={}) -> Promise.try () ->
  accountInfo = _handleAccountInfoTypes(accountInfo)
  query = tables.config.externalAccounts(transaction: opts.transaction)
  .where(name: accountInfo.name)
  if !accountInfo.environment?
    query = query.whereNull('environment')
  else
    query = query.where(environment: accountInfo.environment)
  query = query.update(_transform(_encrypt, opts.cipherKey, accountInfo))
  if opts.logOnly
    return console.log(query.toString())
  query

deleteAccountInfo = (accountInfo, opts={}) -> Promise.try () ->
  accountInfo = _handleAccountInfoTypes(accountInfo)
  query = tables.config.externalAccounts(transaction: opts.transaction)
  .where(name: accountInfo.name)
  .del()

  if opts.logOnly
    return console.log(query.toString())

  query.then (deleted) ->
    _logResult(opts, deleted)



module.exports =
  getAccountInfo: memoize.promise(getAccountInfo, maxAge: 15*60*1000)
  insertAccountInfo: (accountInfo, opts={}) ->
    module.exports.getAccountInfo.delete(accountInfo.name, cipherKey: opts.cipherKey, environment: opts.environment)
    insertAccountInfo(accountInfo, opts)
  updateAccountInfo:  (accountInfo, opts={}) ->
    module.exports.getAccountInfo.delete(accountInfo.name, cipherKey: opts.cipherKey, environment: opts.environment)
    updateAccountInfo(accountInfo, opts)
  deleteAccountInfo:  (accountInfo, opts={}) ->
    module.exports.getAccountInfo.delete(accountInfo.name, cipherKey: opts.cipherKey, environment: opts.environment)
    deleteAccountInfo(accountInfo, opts)
