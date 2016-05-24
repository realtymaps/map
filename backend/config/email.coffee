nodemailer = require 'nodemailer'
externalAccounts = require '../services/service.externalAccounts'
Promise = require 'bluebird'

getMailer = () ->
  externalAccounts.getAccountInfo('gmail')
  .then (accountInfo) ->
    mailer = nodemailer.createTransport
      service: 'Gmail'
      auth:
        user: accountInfo.username
        pass: accountInfo.password

    Promise.promisifyAll mailer

module.exports = {
  getMailer
}
