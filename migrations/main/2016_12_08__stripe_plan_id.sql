ALTER TABLE auth_user ADD COLUMN stripe_plan_id TEXT;

UPDATE auth_user
SET stripe_plan_id = 'pro'
WHERE is_superuser = true or is_staff = true;
