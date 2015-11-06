nodemailer = require 'nodemailer'
externalAccounts = require '../services/service.externalAccounts'


module.exports =
  getMailer: () ->
    externalAccounts.getAccountInfo('gmail')
    .then (accountInfo) ->
      nodemailer.createTransport
        service: 'Gmail'
        auth:
          user: accountInfo.username
          pass: accountInfo.password
