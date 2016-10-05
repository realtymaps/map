UPDATE config_data_normalization
SET ordering = (ordering + 2)
WHERE data_source_id = 'swflmls' AND list = 'base' AND ordering > 4;

-- the above fails: duplicate key value violates unique constraint "unique_rule"

UPDATE config_data_normalization
SET input = '"DOM"'
WHERE data_source_id = 'swflmls' AND list = 'base' AND output = 'days_on_market';

UPDATE config_data_normalization
SET required = true
WHERE data_source_id = 'swflmls' AND list = 'base' AND output = 'close_date';

INSERT INTO "config_data_normalization"
  ("data_source_id","list","output","ordering","required","input","transform","config","data_source_type","data_type")
VALUES
  ('swflmls', 'base', 'days_on_market_cumulative', 5, true, '"CDOM"', NULL, '{"nullZero":true}', 'mls', 'listing')
  ('swflmls', 'base', 'days_on_market_filter', 6, true, '{"cdom":"CDOM","dom":"DOM","creation_date":"Created Date","close_date":"Close Date"}', NULL, '{}', 'mls', 'listing');
