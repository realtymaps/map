ALTER TABLE project ADD COLUMN "minPrice" integer;
ALTER TABLE project ADD COLUMN "beds" integer;
ALTER TABLE project ADD COLUMN "baths" integer;
ALTER TABLE project ADD COLUMN "sqft" integer;
ALTER TABLE project ADD COLUMN "auth_user_id" integer;

ALTER TABLE ONLY project
    ADD CONSTRAINT project_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth_user(id);
