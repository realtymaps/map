logger = require '../config/logger'
mlsSvc = require('../services/service.properties.mls')

module.exports =
  getAll: (req, res) ->
    list = req.path.split("/")
    list.forEach (item) ->
      switch tItem
        when "name", "address", "city", "state", "zipcode"
          obj[tItem] = decodeURIComponent(list.shift().replace(/\+/g, " "))
        when "acres"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "price"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "type"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "bounds"
          obj[tItem] = decodeURIComponent(list.shift()).split(",")

    mlsSvc.getAllMLS(obj).then (json) ->
      res.send json
