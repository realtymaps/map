tables = require '../config/tables'
{expectSingleRow, jsonSafeArray} = require '../utils/util.sql.helpers'
Promise = require 'bluebird'
require '../config/promisify'
memoize = require 'memoizee'
Encryptor = require '../utils/util.encryptor'
config = require '../config/config'
logger = require('../config/logger').spawn('externalAccounts')
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
  cipherKey = opts.cipherKey ? config.ENCRYPTION_AT_REST
  environment = opts.environment ? config.ENV
  tables.config.externalAccounts(transaction: opts.transaction)
  .where(name: name)
  .where () ->
    this.where(environment: environment)
    .orWhereNull('environment')
  .orderBy('environment')
  .then expectSingleRow
  .then _transform.bind(null, _decrypt, cipherKey)
  .then _logResult.bind(null, opts)

insertAccountInfo = (accountInfo, opts={}) -> Promise.try () ->
  accountInfo = _handleAccountInfoTypes(accountInfo)
  cipherKey = opts.cipherKey ? config.ENCRYPTION_AT_REST
  query = tables.config.externalAccounts(transaction: opts.transaction)
  .insert(_transform(_encrypt, cipherKey, accountInfo))
  if opts.logOnly
    return console.log(query.toString())
  query

updateAccountInfo = (accountInfo, opts={}) -> Promise.try () ->
  accountInfo = _handleAccountInfoTypes(accountInfo)
  cipherKey = opts.cipherKey ? config.ENCRYPTION_AT_REST
  query = tables.config.externalAccounts(transaction: opts.transaction)
  .where(name: accountInfo.name)
  if !accountInfo.environment?
    query = query.whereNull('environment')
  else
    query = query.where(environment: accountInfo.environment)
  query = query.update(_transform(_encrypt, cipherKey, accountInfo))
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

  query.then _logResult.bind(null, opts)



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
