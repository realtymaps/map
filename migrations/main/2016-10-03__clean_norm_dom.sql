-- repurpose swfl's old days_on_market for creation_date
UPDATE config_data_normalization
SET output = 'creation_date', input = '"Created Date"', config = '{"advanced":false}', required = true
WHERE data_source_id = 'swflmls' AND list = 'base' AND output = 'days_on_market';

-- remove everybody elses days_on_market;  really only necessary for swfl, but
--   this defensively cleans out the deprecated 'input's to make sure field is red to indicate need update
DELETE FROM config_data_normalization
WHERE output = 'days_on_market';

-- add working days_on_market fields
INSERT INTO "config_data_normalization"
  ("data_source_id","list","output","required","ordering","input","transform","config","data_source_type","data_type")
VALUES
  ('swflmls', 'base', 'days_on_market', false, 24, '"DOM"', NULL, '{"nullZero":true}', 'mls', 'listing'),
  ('swflmls', 'base', 'days_on_market_cumulative', false, 25, '"CDOM"', NULL, '{"nullZero":true}', 'mls', 'listing'),
  ('swflmls', 'base', 'days_on_market_filter', true, 26, '{"cdom":"CDOM","dom":"DOM","creation_date":"Created Date","close_date":"Close Date"}', NULL, '{}', 'mls', 'listing');
