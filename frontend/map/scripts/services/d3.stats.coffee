app = require '../app.coffee'
d3 = require 'd3'

app.service 'rmapsD3Stats', (rmapsPropertyFormatterService) ->
  create = (dataSet) ->
    d3.nest()
    .key (d) ->
      d.status
    .rollup (status) ->
      valid_price = status.filter (p) -> p.price?
      valid_sqft = status.filter (p) -> p.sqft_finished?
      valid_price_sqft = status.filter (p) -> p.price? && p.sqft_finished?
      valid_dom = status.filter (p) -> p.days_on_market?
      valid_cdom = status.filter (p) -> p.days_on_market_cumulative?
      valid_acres = status.filter (p) -> p.acres?

      count: status.length
      price_avg: d3.mean(valid_price, (p) -> p.price)
      price_n: valid_price.length
      sqft_avg: d3.mean(valid_sqft, (p) -> p.sqft_finished)
      sqft_n: valid_sqft.length
      price_sqft_avg: d3.mean(valid_price_sqft, (p) -> p.price/p.sqft_finished)
      price_sqft_n: valid_price_sqft.length
      days_on_market_avg: d3.mean valid_dom, (p) ->
        rmapsPropertyFormatterService.getDaysOnMarket(p)
      days_on_market_n: valid_dom.length
      cdays_on_market_avg: d3.mean valid_cdom, (p) ->
        rmapsPropertyFormatterService.getCumulativeDaysOnMarket(p)
      cdays_on_market_n: valid_cdom.length
      acres_avg: d3.mean(valid_acres, (p) -> p.acres)
      acres_n: valid_acres.length

    .entries(dataSet)

  {
    create
  }
