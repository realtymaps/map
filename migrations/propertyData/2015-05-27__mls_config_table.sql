DROP TABLE IF EXISTS mls_config;
CREATE TABLE mls_config (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    notes TEXT NOT NULL,
    active BOOLEAN DEFAULT false NOT NULL,
    username TEXT NOT NULL,
    password TEXT NOT NULL, /* encrypted */
    URL TEXT NOT NULL,
    main_property_data JSON NOT NULL,
    query_template TEXT DEFAULT '[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]' NOT NULL
);
