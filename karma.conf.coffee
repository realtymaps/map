istanbul = require('istanbul')

module.exports = (config) ->
  config.set
    # base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: './'

    # frameworks to use
    # available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha','fixture','chai', 'expect', 'browserify']

    # preprocess matching files before serving them to the browser
    # available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      'spec/common/**/*spec.coffee': ['browserify']
      'spec/frontend/**/*spec.coffee': ['browserify']
      'spec/fixtures/*.html': ['html2js']
      'spec/fixtures/*.json': ['html2js']
      'bower_components/angular-google-maps/spec/coffee/helpers/google-api-mock.coffee': ['coffee']
      'frontend/**/scripts/**/*.coffee': ['browserify']
    }

    browserify:
      debug: true
      #NOTE transform WILL NOT WORK HERE IFF a transform exists in the package.json
      # THEREFORE it must go in the gulp task
      # transform: ['coffeeify', 'brfs', ["istanbul-ignoreify",{"ignore": ["**/spec/**"]}]]
      transform: ['coffeeify', 'jadeify', 'stylusify', 'brfs',
        ["browserify-istanbul",
          ignore: ["spec/**/*"]
          #https://github.com/karma-runner/karma-coverage/issues/157#issuecomment-160555004
          #fixes the text karma-coverage error
          instrumenterConfig: { embedSource: true }
        ]
      ]
      # extensions: ['.coffee', '.js']


      ### PROBLEM 2
        17 09 2015 16:44:06.455:ERROR [coverage]: [TypeError: Cannot read property 'text' of undefined]
        see: https://github.com/karma-runner/karma-coverage/issues/157
      ###
    coverageReporter:
      #https://github.com/karma-runner/karma-coverage/blob/master/docs/configuration.md#sourcestore
      reporters:[
        {
          type : 'html'
          dir : '_public/coverage/'
          subdir: "application"
          sourceStore : istanbul.Store.create('fslookup')
        }
        {
          type : 'cobertura'
          dir : '_public/coverage/'
          subdir: "application"
          sourceStore : istanbul.Store.create('fslookup')
        }
      ]

    # list of files / patterns to load in the browser
    files: [
      'node_modules/phantomjs-polyfill/bind-polyfill.js'
      require.resolve('stripe-debug')#https://github.com/bendrucker/angular-stripe/issues/23
      '_public/scripts/vendor.js'
      '_public/styles/vendor.css'
      'frontend/**/scripts/**/*.coffee'
      'bower_components/angular-google-maps/spec/coffee/helpers/google-api-mock.coffee'
      'spec/fixtures/*.html'
      'spec/fixtures/*.json'
      'spec/frontend/bootstrap.spec.coffee'
      {pattern:'frontend/**/*coffee', included: false}
      {pattern:'common/**/*coffee', included: false}
      {pattern:'spec/**/*coffee', included: false}
      # 'spec/common/**/*spec.coffee'
      'spec/frontend/**/*spec.coffee'
    ]

    # list of files to exclude
    exclude: [
    ]

    # test results reporter to use
    # possible values: 'dots', 'progress'
    # available reporters: https://npmjs.org/browse/keyword/karma-reporter
    # NOTE , TODO 'html' reporter use if you want to hit the karma jasmine runner (frequently causes karma to blow up at the end of run),
    # test results reporter to use
    # possible values: 'dots', 'progress', 'mocha'
    reporters: ['mocha', 'coverage']

    # htmlReporter:
    #   middlePathDir: "chrome"
    #   outputDir: '_public/karma_html',
    #   templatePath: 'spec/karma_jasmine_runner.html'

    # web server port
    port: 9876

    # enable / disable colors in the output (reporters and logs)
    colors: true

    # level of logging
    # possible values:
    # - config.LOG_DISABLE
    # - config.LOG_ERROR
    # - config.LOG_WARN
    # - config.LOG_INFO
    # - config.LOG_DEBUG
    logLevel: config.LOG_INFO

    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: false

    # start these browsers
    # available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['PhantomJS']# options Chrome, PhantomJS
    #browserNoActivityTimeout: 200000000000000000000000000000000
    # If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000
    # Continuous Integration mode
    # if true, Karma captures browsers, runs the tests and exits
    singleRun: true
