-- make the database work for u
ALTER TABLE auth_m2m_user_groups DROP CONSTRAINT user_id_refs_id_40c41112;

ALTER TABLE auth_m2m_user_groups ADD CONSTRAINT auth_user_groups_user_id_fkey
FOREIGN KEY ("user_id") REFERENCES auth_user ("id")
ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
