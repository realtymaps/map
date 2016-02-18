-- make the database work for u
ALTER TABLE auth_m2m_user_permissions DROP CONSTRAINT user_id_refs_id_4dc23c39;

ALTER TABLE auth_m2m_user_permissions ADD CONSTRAINT auth_user_permissions_user_id_fkey
FOREIGN KEY ("user_id") REFERENCES auth_user ("id")
ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
