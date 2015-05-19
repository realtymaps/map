ALTER TABLE auth_user
ADD COLUMN cell_phone bigint DEFAULT NULL,
ADD COLUMN work_phone bigint DEFAULT NULL;
