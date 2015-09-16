rewire = require 'rewire'

describe 'config', ->
  beforeEach ->
    @subject = rewire '../../../backend/config/config'
    
  describe '_getConfig', ->
    it 'can get value', ->
      config =
        DIGIMAPS_PASSWORD: 'pass'
    
      _getConfig = @subject.__get__('_getConfig')
      expect(_getConfig('DIGIMAPS', 'PASSWORD',  '_', config))
      .to.be.eql(config.DIGIMAPS_PASSWORD)
    
  describe '_getAllConfigs', ->
    it 'can get many values', ->
      config =
        DIGIMAPS_PASSWORD: 'pass'
        DIGIMAPS_CRAP: 'crap'
        DIGIMAPS_CRAP2: 'crap2'
    
      _getAllConfigs = @subject.__get__('_getAllConfigs')
      vals = _getAllConfigs('DIGIMAPS',
        ['PASSWORD', 'CRAP', 'CRAP2'], undefined, config)
      expect(vals)
        .to.be.eql
          PASSWORD: config.DIGIMAPS_PASSWORD
          CRAP: config.DIGIMAPS_CRAP
          CRAP2: config.DIGIMAPS_CRAP2
