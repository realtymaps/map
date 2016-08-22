require('coffee-script').register()

exports.config = {
  seleniumAddress: 'http://localhost:4444/wd/hub',
  // framework: 'mocha',
  // tried: https://github.com/domenic/chai-as-promised
  // and https://github.com/angular/protractor/blob/master/docs/frameworks.md
  // tests just hung
  // going with jasmine for now
  specs: [
    './spec/frontendIntegration/**/*.spec.coffee'
  ]
};
