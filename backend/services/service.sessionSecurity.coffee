Promise = require "bluebird"
bcrypt = require 'bcrypt'

logger = require '../config/logger'
User = require("../models/model.user")
environmentSettingsService = require("../services/service.environmentSettings")

module.exports = {
  createNewSeries: (req, res) ->
    
}