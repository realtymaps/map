INSERT INTO test (data) VALUES ('duck1'); INSERT INTO test (data) VALUES ('duck2');
CREATE OR REPLACE FUNCTION
  test1() RETURNS VOID AS
  '
  BEGIN
  END;
  '
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION
  test2() RETURNS VOID AS
  $$
  BEGIN
  END;
  $$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION
  test3() RETURNS VOID AS
  $dollar_tag$
  BEGIN
  END;
  $dollar_tag$
LANGUAGE 'plpgsql';

SELECT '"' AS "test $$";
SELECT '--' AS "test--";
SELECT '/*' AS "test";
SELECT '' AS "*/test";

INSERT INTO test (data) /* inline comment */ VALUES ('duck3'); INSERT INTO test (data) VALUES ('duck4');
INSERT INTO test (data) VALUES goose -- intentionally bad line to force transaction to roll back
