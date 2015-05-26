nodemailer = require 'nodemailer'
config = require './config'

mailer = nodemailer.createTransport
  service: 'Gmail'
  auth:
    user: config.GMAIL.ACCOUNT
    pass: config.GMAIL.PASSWORD

module.exports =
  mailer: mailer