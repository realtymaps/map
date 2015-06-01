DROP TABLE IF EXISTS mls_config;
CREATE TABLE mls_config (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    notes TEXT,
    active BOOLEAN DEFAULT false NOT NULL,
    username TEXT NOT NULL,
    password TEXT NOT NULL, /* encrypted */
    URL TEXT NOT NULL,
    main_property_data JSON NOT NULL
);
