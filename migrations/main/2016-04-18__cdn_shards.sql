CREATE TABLE cdn_shards (
  id int,
  name varchar(15) NOT NULL,
  url varchar(100) NOT NULL,
  cdn_id int4,
  rm_inserted_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc(),
  PRIMARY KEY (id) NOT DEFERRABLE INITIALLY IMMEDIATE
)
WITH (OIDS=FALSE);


CREATE TRIGGER update_modified_time_cdn_shards
BEFORE UPDATE ON cdn_shards
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

insert into cdn_shards
  (id, cdn_id, name, url)
values
  (0, 499053, 'prodpull1', 'prodpull1.realtymapsterllc.netdna-cdn.com'),
  (1, 499059, 'prodpull2', 'prodpull2.realtymapsterllc.netdna-cdn.com');
