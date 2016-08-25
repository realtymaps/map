encyptor = require '../../../backend/config/encryptor'
###globals by, element, browser###
module.exports = (root = 'http://localhost:8085') ->
  browser.get root
  element(`by`.css('.main')).click()

  element(`by`.css('#username')).sendKeys(encyptor.decrypt process.env.FRONTEND_INTEGRATION_EMAIL)

  element(`by`.css('#password')).sendKeys(encyptor.decrypt process.env.FRONTEND_INTEGRATION_PASSWORD)
  element(`by`.css('input[type=submit]')).click()
