DO $$
BEGIN
  ALTER TABLE user_project ADD COLUMN "minPrice" integer;
  ALTER TABLE user_project ADD COLUMN "maxPrice" integer;
  ALTER TABLE user_project ADD COLUMN "beds" integer;
  ALTER TABLE user_project ADD COLUMN "baths" integer;
  ALTER TABLE user_project ADD COLUMN "sqft" integer;
  ALTER TABLE user_project ADD COLUMN "auth_user_id" integer;
  ALTER TABLE ONLY user_project
      ADD CONSTRAINT project_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth_user(id);
EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column already exists';
END;
$$;

UPDATE user_project p SET
  auth_user_id = u.auth_user_id
FROM
  user_profile u
WHERE
  p.id = u.project_id;
