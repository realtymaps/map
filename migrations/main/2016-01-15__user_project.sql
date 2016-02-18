-- make the database work for u
ALTER TABLE user_project DROP CONSTRAINT project_auth_user_id_fkey;

ALTER TABLE user_project ADD CONSTRAINT project_auth_user_id_fkey
FOREIGN KEY ("auth_user_id") REFERENCES auth_user ("id")
ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
