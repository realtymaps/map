# app = require '../../app.coffee'
# replaceCCModalTemplate = require('../../../html/views/templates/modals/replaceCC.jade')()
# module.exports = app
# _ = require 'lodash'

# app.controller 'rmapsUserPaymentMethodCtrl', (
# $scope
# $log
# $uibModal
# stripe
# rmapsPaymentMethodService) ->

#   $log = $log.spawn("map:userPaymentMethod")

#   $scope.payment = null
#   customer_id = null

#   rmapsPaymentMethodService.getDefaultSource()
#   .then (source) ->
#     $scope.payment = source
#     customer_id = source.customer

#   # self-service modal for replacing CC
#   $scope.replaceCC = () ->
#     modalInstance = $uibModal.open
#       animation: true
#       template: replaceCCModalTemplate
#       controller: 'rmapsReplaceCCModalCtrl'
#       resolve:
#         modalTitle: () ->
#           return "Replace Credit Card"

#         showCancelButton: () ->
#           return false

#     modalInstance.result.then (result) ->
#       if !result then return

#       # update payment with returned credit card
#       $scope.payment = result



