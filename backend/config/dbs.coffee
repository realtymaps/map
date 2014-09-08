knex = require 'knex'
bookshelf = require 'bookshelf'
config = require './config'

module.exports = 
  users: bookshelf(knex(config.USER_DB))
  properties: bookshelf(knex(config.PROPERTY_DB))
