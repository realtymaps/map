ALTER TABLE user_state
DROP COLUMN IF EXISTS map_center,
DROP COLUMN IF EXISTS map_zoom;

-- clear invalid sessions since session state is now outdated
DELETE FROM session;
