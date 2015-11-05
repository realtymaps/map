
ALTER TABLE config_external_accounts ADD COLUMN url TEXT;
ALTER TABLE config_external_accounts ADD COLUMN environment TEXT;
ALTER TABLE config_external_accounts DROP COLUMN id;
CREATE INDEX ON config_external_accounts (name);
CREATE UNIQUE INDEX ON config_external_accounts (name, environment);


UPDATE jq_task_config
  SET data = '{}'
  WHERE name = 'parcel_update';

UPDATE jq_task_config
  SET data = '{}'
  WHERE name = 'corelogic';

ALTER TABLE config_mls DROP COLUMN username;
ALTER TABLE config_mls DROP COLUMN password;
ALTER TABLE config_mls DROP COLUMN url;
