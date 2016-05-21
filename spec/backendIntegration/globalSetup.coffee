path = require 'path'

basePath = path.join __dirname, '../../backend'
commonPath = path.join __dirname, '../../common'

emailConfig =  require "#{basePath}/config/email"

sinon = require 'sinon'
Promise = require 'bluebird'


before ->

  # mock out emailer as to not spam emails in integration specs
  # (for those who have email config_notification rows)
  emailConfig.getMailer = sinon.stub().returns Promise.resolve
    sendMailAsync: sinon.stub().returns Promise.resolve()


after ->
  dbs = require("#{basePath}/config/dbs")
  return dbs.shutdown(quiet: true)


module.exports = {basePath, commonPath}
