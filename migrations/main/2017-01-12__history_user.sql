ALTER TABLE history_user add column id SERIAL PRIMARY KEY;
ALTER TABLE history_user add column rm_modified_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now_utc();


CREATE TRIGGER update_modified_time_history_user
BEFORE UPDATE ON history_user
FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column();

ALTER TABLE history_user add column category_id int4;
ALTER TABLE history_user add column subcategory_id int4;

ALTER TABLE history_user drop column subcategory;
ALTER TABLE history_user drop column category;
