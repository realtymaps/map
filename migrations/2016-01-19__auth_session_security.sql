-- make the database work for u
ALTER TABLE auth_session_security DROP CONSTRAINT session_security_user_id_fkey;

ALTER TABLE auth_session_security ADD CONSTRAINT session_security_user_id_fkey
FOREIGN KEY ("user_id") REFERENCES auth_user ("id")
ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
