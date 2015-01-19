app = require '../app.coffee'

app.service 'uiGmapControls'.ourNs(), [ ->

  class Controls
    init: (controls) ->
      @controls = controls

     #specifc we have id of only 3 controls to update
    eachSpecificChildModel: (id, cb, toGetFn , excepts = undefined) =>
      _.each @controls, (control, k) ->
        return if excepts? and _.contains(excepts, k)
        propMap = control.getPlurals() if control? and control.getPlurals?
        return unless propMap
        childModel = propMap.get(id)
        got = if toGetFn? then toGetFn(childModel) else childModel
        cb(got) if got?

    eachSpecificGObject: (id, cb, excepts) =>
      @eachSpecificChildModel id, (childModel) ->
        cb(childModel.gObject) if childModel? and childModel.gObject?
      , undefined, excepts

    ###
      So ideally with MVC we would not do this, but there are many cases where uiGmap is not staying in sync.
      So here we update the state of a model without a watcher.
    ###
    updateAllModels: (toUpdate, id = 'rm_property_id') =>
      @eachSpecificChildModel toUpdate[id], (childModel) ->
        childModel.model = toUpdate
  new Controls()

]