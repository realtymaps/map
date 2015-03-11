ALTER TABLE user_state
ADD COLUMN map_position JSON DEFAULT NULL,
ADD COLUMN map_results JSON NOT NULL DEFAULT '{}';

-- Combine seperate cols into a json object and assign it to the new col
-- map_position
UPDATE user_state
SET map_position = ('{"center": '||map_center||', "zoom": '||map_zoom||'}')::JSON;
