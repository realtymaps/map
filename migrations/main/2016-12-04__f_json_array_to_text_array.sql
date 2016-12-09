-- http://dba.stackexchange.com/questions/54283/how-to-turn-json-array-into-postgres-array
CREATE OR REPLACE FUNCTION jsonb_array_to_text_array(
  p_input jsonb
) RETURNS TEXT[] AS $BODY$

DECLARE v_output text[];

BEGIN

  SELECT array_agg(ary)::text[]
  INTO v_output
  FROM jsonb_array_elements_text(p_input) AS ary;

  RETURN v_output;

END;

$BODY$
LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION json_array_to_text_array(
  p_input json
) RETURNS TEXT[] AS $BODY$

DECLARE v_output text[];

BEGIN

  SELECT array_agg(ary)::text[]
  INTO v_output
  FROM json_array_elements_text(p_input) AS ary;

  RETURN v_output;

END;

$BODY$
LANGUAGE plpgsql VOLATILE;
