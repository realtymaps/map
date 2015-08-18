
module.exports =
  rmap: (req, res, next) ->
    res.render 'map',
      ngApp:'rmapsMapApp'

  admin: (req, res, next) ->
    res.render 'admin',
      ngApp:'rmapsAdminApp'

  mocksResults: (req, res, next) ->
    res.render 'mocks/results-tray'
