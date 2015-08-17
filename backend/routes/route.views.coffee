
module.exports =
  rmap: (req, res, next) ->
    res.render 'map',
      ngApp:'rmapsmapapp'

  admin: (req, res, next) ->
    res.render 'admin',
      ngApp:'rmapsadminapp'

  mocksResults: (req, res, next) ->
    res.render 'mocks/results-tray'
