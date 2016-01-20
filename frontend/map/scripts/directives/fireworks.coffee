app = require '../app.coffee'
Render = require './utils/webGl/render.js'
boomboomFact = require './utils/webGl/boomboom.js'

app.directive 'fireworks', ($log) ->
  template: """<div class='fireworks'></div>"""
  replace:true
  link: (scope, element, attrs) ->
    [node] = element
    render = Render._init(node)
    boomboom = boomboomFact(render)
    boomboom._init(node)

    scope.$on "$destroy" , ->
      render._kill(node)
      boomboom._kill(node)
