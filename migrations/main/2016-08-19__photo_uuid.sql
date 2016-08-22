ALTER TABLE data_photo
ADD COLUMN
data_source_id text NOT NULL;

ALTER TABLE data_photo
ADD COLUMN
data_source_uuid text NOT NULL;

ALTER TABLE data_photo
DROP COLUMN rm_property_id;

ALTER TABLE data_photo
DROP COLUMN photo_id;

ALTER TABLE data_photo
DROP COLUMN photo_count;

ALTER TABLE data_photo
ADD PRIMARY KEY (data_source_id, data_source_uuid);

UPDATE jq_task_config SET active=false where name like '<default%';
