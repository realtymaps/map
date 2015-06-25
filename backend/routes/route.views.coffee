
module.exports =
  rmap: (req, res, next) ->
    res.render 'rmap',
      ngApp:'rmapsapp'

  admin: (req, res, next) ->
    res.render 'admin',
      ngApp:'rmapsadminapp'

  mocksResults: (req, res, next) ->
    res.render 'mocks/results-tray'
