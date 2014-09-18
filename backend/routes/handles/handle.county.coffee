logger = require '../config/logger'
countySvc = require('../services/service.properties.county')()

module.exports = (next) ->
  
  getAll: (req, res) ->

    # TODO: Query params should exist without the need to split
    # Parse url path to get query params
    # http://stackoverflow.com/questions/6912584/how-to-get-get-query-string-variables-in-node-js
    list = req.path.split("/")
    list.forEach (item) ->
      switch tItem
        when "name", "address", "city", "state", "zipcode", "apn"
          obj[tItem] = decodeURIComponent(list.shift().replace(/\+/g, " "))
        when "soldwithin"
          obj[tItem] = decodeURIComponent(list.shift().replace(/\+/g, " "))
        when "acres"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "price"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "type"
          obj[tItem] = decodeURIComponent(list.shift()).split("-")
        when "bounds"
          obj[tItem] = decodeURIComponent(list.shift()).split(",")
        when "polys"
          obj[tItem] = decodeURIComponent(list.shift()).split(",")

    countySvc.getAll(obj).then (json) ->
      res.send json

  getAddresses: (req, res) ->
    list = req.path.split("/")
    list.forEach (item) ->
      tItem = list.shift()
      switch tItem
        when "bounds"
          obj[tItem] = decodeURIComponent(list.shift()).split(",")

    countySvc.getAddresses(obj).then (json) ->
      res.send json

  getApn: (req, res) ->
    list = req.path.split("/")
    list.forEach (item) ->
      switch tItem
        when "apn"
          obj[tItem] = decodeURIComponent(list.shift().replace(/\+/g, " "))
        when "bounds"
          obj[tItem] = decodeURIComponent(list.shift()).split(",")

    countySvc.getByApn(obj).then (json) ->
      res.send json
