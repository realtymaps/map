DELETE FROM auth_session WHERE sess->>'userid' IS NULL;

