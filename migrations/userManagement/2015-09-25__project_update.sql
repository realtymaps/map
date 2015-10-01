DO $$
BEGIN
    ALTER TABLE project ADD COLUMN archived boolean;
EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column project.archived already exists';
END;
$$;
