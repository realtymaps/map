UPDATE config_data_normalization
SET config = '{"nullEmpty":true,"trim":true,"forceLookups":true,"mapping":{"0":"inactive","1":"active"}}'::JSON
WHERE
  data_source_id = 'RAPB'
  AND list = 'base'
  AND output = 'agent_status'
  AND data_type = 'agent';
