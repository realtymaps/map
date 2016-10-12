stampit = require 'stampit'
app = require '../../app.coffee'

app.factory 'rmapsLayerManager', (
$log
rmapParcelMutation
rmapClusterMutation
rmapSummaryMutation
) ->
  $log = $log.spawn 'rmapsLayerManager'
  flowFact = stampit.compose(rmapParcelMutation, rmapClusterMutation, rmapSummaryMutation)

  ({scope, filters, hash, mapState, data, event}) ->
    $log.debug -> event

    flow = flowFact({scope, filters, hash, mapState, data})

    flow
    .mutateCluster()
    .mutateSummary()

    promise = flow.mutateParcel()

    #make the promise apparent as an undefined promise will just pass through and make
    #q.all a nightmare to debug. This was the main big bug originally in here
    if !promise
      throw new Error 'rmapsLayerManager promise is undefined'
    promise
