nodemailer = require 'nodemailer'
config = require './config'

mailer = nodemailer.createTransport
  service: 'Gmail'
  auth:
    user: config.GMAIL.ACCOUNT
    pass: config.GMAIL.PASSWORD

# fail silent w/o mail creds

module.exports =
  mailer: mailer