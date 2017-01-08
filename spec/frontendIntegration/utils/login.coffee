###globals by, element, browser###
module.exports = (root = 'http://localhost:8085/map') ->
  browser.get root

  element(`by`.css('#email')).sendKeys(process.env.FRONTEND_INTEGRATION_EMAIL)

  element(`by`.css('#password')).sendKeys(process.env.FRONTEND_INTEGRATION_PASSWORD)
  element(`by`.css('input[type=submit]')).click()
