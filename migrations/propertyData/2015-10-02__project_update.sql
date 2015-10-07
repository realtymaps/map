DO $$
BEGIN
    -- the duplication is not necessary for most folks, it was just the easiest way for me to handle things locally
    -- since I'd already renamed the table via my own migration
    ALTER TABLE IF EXISTS project ADD COLUMN archived boolean;
    ALTER TABLE IF EXISTS user_project ADD COLUMN archived boolean;
EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column project.archived already exists';
END;
$$;
