
ALTER TABLE data_combined DROP COLUMN IF EXISTS baths_full;
ALTER TABLE data_combined DROP COLUMN IF EXISTS baths_half;
ALTER TABLE data_combined DROP COLUMN IF EXISTS baths;
ALTER TABLE data_combined ADD COLUMN baths JSON;
