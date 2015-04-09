DROP TABLE IF EXISTS test;
CREATE TABLE test (
    "id" serial NOT NULL PRIMARY KEY,
    "timestamp" timestamp with time zone NOT NULL DEFAULT now(),
    "data" TEXT
);
INSERT INTO test (data) VALUES ('1');
INSERT INTO test (data) VALUES ('2');
INSERT INTO test (data) VALUES ('3');
