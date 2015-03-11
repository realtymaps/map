create or replace function now_utc() returns timestamp as $$
  select now() at time zone 'utc';
  $$ language sql;

-- Stored Procedure for keeping modified_time always fresh on real changes
CREATE OR REPLACE FUNCTION update_rm_modified_time_column()
  RETURNS TRIGGER AS '
BEGIN
  NEW.rm_modified_time = NOW();
  RETURN NEW;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION
  ignore_blank(prefix TEXT, str TEXT, suffix TEXT) RETURNS TEXT AS
  $$
  BEGIN
    IF str IS NULL OR str = '' THEN
      RETURN '';
    END IF;
    RETURN prefix||str||suffix;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  build_street_address_name(dir TEXT, str TEXT, suf TEXT, quad TEXT) RETURNS TEXT AS
  $$
  DECLARE
    result TEXT;
  BEGIN
    result := ignore_blank('',dir,' ')
            ||ignore_blank('',str,'')
            ||ignore_blank(' ',suf,'')
            ||ignore_blank(' ',quad,'');
    RETURN nullif(result, '');
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  build_zip(zip5 TEXT, zip4 TEXT) RETURNS TEXT AS
  $$
  DECLARE
    result TEXT;
  BEGIN
    result := ignore_blank('',zip5,'') || ignore_blank('-',zip4,'');
    IF char_length(result) = '9' AND result !~ '-' THEN
      result := substring(result FROM 1 FOR 5) || '-' || substring(result FROM 6 FOR 4);
    END IF;
    RETURN nullif(result, '');
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  build_name(first_name_mi TEXT, last_name TEXT) RETURNS TEXT AS
  $$
  DECLARE
    result TEXT;
  BEGIN
    result := ignore_blank('', first_name_mi, '') || ignore_blank(' ', last_name, '');
    RETURN nullif(result, '');
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  property_indication_category(ind TEXT) RETURNS TEXT AS
  $$
  BEGIN
    CASE
      WHEN ind = '00' THEN RETURN 'Miscellaneous';
      WHEN ind BETWEEN '10' AND '19' THEN RETURN 'Residential';
      WHEN ind BETWEEN '20' AND '49' THEN RETURN 'Commercial';
      WHEN ind BETWEEN '50' AND '69' THEN RETURN 'Industrial';
      WHEN ind BETWEEN '70' AND '79' THEN RETURN 'Agricultural';
      WHEN ind BETWEEN '80' AND '89' THEN RETURN 'Vacant';
      WHEN ind BETWEEN '90' AND '99' THEN RETURN 'Exempt';
      ELSE RETURN NULL;
    END CASE;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  property_indication_name(ind TEXT) RETURNS TEXT AS
  $$
  BEGIN
    CASE
      WHEN ind = '10' THEN RETURN 'Single Family Residence or Townhouse';
      WHEN ind = '11' THEN RETURN 'Condominium (residential)';
      WHEN ind = '21' THEN RETURN 'Duplex, Triplex, or Quadplex';
      WHEN ind = '22' THEN RETURN 'Apartment';
      WHEN ind = '23' THEN RETURN 'Hotel or Motel';
      WHEN ind = '24' THEN RETURN 'Condominium (commercial)';
      WHEN ind = '25' THEN RETURN 'Retail';
      WHEN ind = '26' THEN RETURN 'Service (general public)';
      WHEN ind = '27' THEN RETURN 'Office Building';
      WHEN ind = '28' THEN RETURN 'Warehouse';
      WHEN ind = '29' THEN RETURN 'Financial Institution';
      WHEN ind = '30' THEN RETURN 'Hospital, Medical Complex, or Clinic';
      WHEN ind = '31' THEN RETURN 'Parking';
      WHEN ind = '32' THEN RETURN 'Amusement / Recreation';
      WHEN ind = '50' THEN RETURN 'Industrial';
      WHEN ind = '51' THEN RETURN 'Light Industrial';
      WHEN ind = '52' THEN RETURN 'Heavy Industrial';
      WHEN ind = '53' THEN RETURN 'Transport';
      WHEN ind = '54' THEN RETURN 'Utilities';
      ELSE RETURN NULL;
    END CASE;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  make_less_than_null(source_value ANYELEMENT, less_than_value ANYELEMENT) RETURNS ANYELEMENT AS
  $$
  BEGIN
    IF source_value < less_than_value THEN
      RETURN NULL;
    ELSE
      RETURN source_value;
    END IF;
  END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  make_negative_interval_null(source_value INTERVAL) RETURNS INTERVAL AS
  $$
    BEGIN
      RETURN make_less_than_null(source_value, INTERVAL '0')::INTERVAL;
    END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  make_negative_num_null(source_value ANYELEMENT) RETURNS ANYELEMENT AS
  $$
  BEGIN
    RETURN make_less_than_null(source_value, 0::ANYELEMENT)::ANYELEMENT;
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  get_num(qtxt TEXT, str TEXT) RETURNS TEXT AS
  $$
  DECLARE tmp TEXT;
  BEGIN
    tmp := substring(str from qtxt || '(?: .*?)? (\d+)(?:.*)?');
    IF tmp IS NOT NULL THEN
      RETURN tmp;
    END IF;
    tmp := substring(str from '(?:.* )?(\d+)(?: .*)? ' || qtxt);
    IF tmp IS NOT NULL THEN
      RETURN tmp;
    END IF;
    RETURN NULL;
  END;
  $$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION
  normalize_st(stname TEXT) RETURNS TEXT AS
  $$
  DECLARE
    tmp TEXT;
    tmp2 TEXT;
  BEGIN
    tmp = upper(stname);
    IF tmp = 'FIRST' THEN
      RETURN '1ST';
    END IF;
    IF tmp = 'SECOND' THEN
      RETURN '2ND';
    END IF;
    IF tmp = 'THIRD' THEN
      RETURN '3RD';
    END IF;
    IF tmp = 'FOURTH' THEN
      RETURN '4TH';
    END IF;
    IF tmp = 'FIFTH' THEN
      RETURN '5TH';
    END IF;
    IF tmp = 'SIXTH' THEN
      RETURN '6TH';
    END IF;
    IF tmp = 'SEVENTH' THEN
      RETURN '7TH';
    END IF;
    IF tmp = 'EIGHTH' THEN
      RETURN '8TH';
    END IF;
    IF tmp = 'NINTH' THEN
      RETURN '9TH';
    END IF;
    IF tmp = 'TENTH' THEN
      RETURN '10TH';
    END IF;
    
    tmp2 := get_num('FM', tmp);
    IF tmp2 IS NOT NULL THEN
      RETURN tmp2;
    END IF;
    tmp2 := get_num('INTERSTATE', tmp);
    IF tmp2 IS NOT NULL THEN
      RETURN tmp2;
    END IF;
    tmp2 := get_num('STATE', tmp);
    IF tmp2 IS NOT NULL THEN
      RETURN tmp2;
    END IF;
    tmp2 := get_num('STATE HWY', tmp);
    IF tmp2 IS NOT NULL THEN
      RETURN tmp2;
    END IF;
    
    RETURN tmp;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  repair_addresses(fips_to_fix TEXT) RETURNS VOID AS
  $$
  BEGIN
    DROP TABLE IF EXISTS parcels_temp;
    CREATE TABLE parcels_temp as SELECT *, normalize_st(ststname) as nststname FROM parcels WHERE fips = fips_to_fix;
    CREATE INDEX ON parcels_temp (nststname);
    CREATE INDEX ON parcels_temp (sthsnum);
    CREATE INDEX ON parcels_temp (stcity);

    DROP TABLE IF EXISTS tax_temp;
    CREATE TABLE tax_temp as SELECT *, normalize_st(property_street_name) as nproperty_street_name FROM corelogic_tax WHERE fips_code = fips_to_fix;
    CREATE INDEX ON tax_temp (nproperty_street_name);
    CREATE INDEX ON tax_temp (property_house_number);
    CREATE INDEX ON tax_temp (property_city);

    UPDATE parcels SET parcelapn = tax.apn_unformatted FROM tax_temp AS tax, parcels_temp AS p WHERE (tax.property_house_number::INTEGER)::TEXT = p.sthsnum AND tax.nproperty_street_name = p.nststname AND tax.fips_code = fips_to_fix AND tax.property_city = p.stcity AND p.fips = fips_to_fix AND p.id = parcels.id;

    DROP TABLE IF EXISTS parcels_temp;
    DROP TABLE IF EXISTS tax_temp;

    -- remove space from APNs when setting rm_property_id and fix the 0-padding in seq
    -- we'll want to be sure both of these things are handled properly elsewhere in the long term, but this works for now
    UPDATE parcels
    SET
      rm_property_id =
      fips || '_' ||
      regexp_replace(parcelapn, ' ', '', 'g') || '_001'
    WHERE fips = fips_to_fix;
  END;
  $$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  build_street_address_num(pref TEXT, num TEXT, num2 TEXT, numsuf TEXT) RETURNS TEXT AS
  $$
  DECLARE
    result TEXT;
  BEGIN
    result := ignore_blank('',pref,'')
            ||ignore_blank('',trim(LEADING '0' FROM num),'')
            ||ignore_blank('',trim(LEADING '0' FROM num2),'')
            ||ignore_blank('',numsuf,'');
    RETURN nullif(result, '');
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  build_street_address_unit(upref TEXT, unum TEXT) RETURNS TEXT AS
  $$
  DECLARE
    result TEXT;
  BEGIN
    result := ignore_blank('',upref,'') || ignore_blank('',trim(LEADING '0' FROM unum),'');
    RETURN nullif(result, '');
  END;
  $$
LANGUAGE plpgsql;


-- sucks that I have to do this...  the logic gets hard to think about considering that we can have dates without prices
-- as well as prices without dates.  The goal though is to find the most recent date that isn't null and has a price,
-- and return that.  But, in the case where there isn't a date-price pair that are both non-null, we want to return the
-- first value which isn't null.  I think this function accomplishes that logic.
CREATE OR REPLACE FUNCTION
  get_most_recent_associated(source_value1 DATE, source_value2 DATE, source_value3 DATE, source_value4 DATE, result_value1 ANYELEMENT, result_value2 ANYELEMENT, result_value3 ANYELEMENT, result_value4 ANYELEMENT) RETURNS ANYELEMENT AS
  $$
  DECLARE
    recent_date DATE;
    recent_value TEXT;
  BEGIN

    recent_date := source_value4;
    recent_value := result_value4::TEXT;

    IF (recent_date IS NULL OR source_value3 > recent_date) AND result_value3 IS NOT NULL THEN
      recent_date := source_value3;
      recent_value := result_value3::TEXT;
    END IF;

    IF (recent_date IS NULL OR source_value2 > recent_date) AND result_value2 IS NOT NULL THEN
      recent_date := source_value2;
      recent_value := result_value2::TEXT;
    END IF;

    IF (recent_date IS NULL OR source_value1 > recent_date) AND result_value1 IS NOT NULL THEN
      recent_date := source_value1;
      recent_value := result_value1::TEXT;
    END IF;

    RETURN recent_value;
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  expand_subqueries(orig_definition TEXT) RETURNS TEXT AS
  $$
  DECLARE
    definition TEXT;
    recursive_id TEXT;
  BEGIN
    definition := orig_definition;
    LOOP
      recursive_id := substring(definition FROM '{__(\w+)__}');
      EXIT WHEN recursive_id IS NULL;
      definition := replace(definition, '{__'||recursive_id||'__}', '('||build_view_query(recursive_id)||')');
    END LOOP;
    RETURN definition;
  END
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  newline() RETURNS TEXT AS
  $$
  BEGIN
    RETURN '
';
  END
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  build_partial_view_query(id TEXT, section TEXT, join_str TEXT) RETURNS TEXT AS
  $$
  DECLARE
    row view_definitions%ROWTYPE;
    partials TEXT ARRAY;
  BEGIN
    partials := '{}';
    FOR row IN SELECT * FROM view_definitions
    WHERE view_id = id AND clause_type = section
    ORDER BY ordering
    LOOP
      partials := partials || ( expand_subqueries(row.definition) || ignore_blank(' AS ', row.name, '') || ignore_blank(' ON ', row.aux, '') );
    END LOOP;
    IF array_length(partials, 1) > 0 THEN
      RETURN section || newline() || array_to_string(partials, join_str||newline());
    ELSE
      RETURN '';
    END IF;
  END
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  build_view_query(id TEXT) RETURNS TEXT AS
  $$
  DECLARE
    query_text TEXT;
  BEGIN
    query_text := build_partial_view_query(id, 'SELECT', ',');
    query_text := query_text || ignore_blank(newline(), build_partial_view_query(id, 'FROM', ''), '');
    query_text := query_text || ignore_blank(newline(), build_partial_view_query(id, 'WHERE', ' AND'), '');
    query_text := query_text || ignore_blank(newline(), build_partial_view_query(id, 'ORDER BY', ','), '');
    IF query_text = '' THEN
      RETURN 'SELECT NULL AS dummy';
    ELSE
      RETURN query_text;
    END IF;
  END;
  $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  parcel_status3(status TEXT, has_mls_listing BOOLEAN, mls_close_date TIMESTAMP, sale_date1 TIMESTAMP, sale_date2 TIMESTAMP, sale_date3 TIMESTAMP, recent TEXT, as_of TIMESTAMP) RETURNS TEXT AS
  $$
  DECLARE
    relevant_close_date TIMESTAMP;
  BEGIN
    IF has_mls_listing AND mls_close_date IS NULL THEN
      -- if there's an open MLS listing, then we have to run this logic off the mls close date
      relevant_close_date := NULL;
    ELSE
      -- otherwise, use the most recent (non-NULL) close date
      relevant_close_date := GREATEST(mls_close_date, sale_date1, sale_date2, sale_date3);
    END IF;

    -- if there is no closing date, then we have to trust the status; for now that only tells us Active or Sold,
    -- but we may have to generalize this if other MLS data works differently e.g. if it doesn't provide a close date,
    -- but does give an explicit status value for Pending
    IF relevant_close_date IS NULL THEN
      IF status = 'Active' THEN
        RETURN 'for sale';
      ELSE
        RETURN 'not for sale';
      END IF;
    END IF;
    
    -- if we get a close_date, trust it to differentiate pending vs recently sold vs sold a while ago (not for sale) 
    IF relevant_close_date::TIMESTAMP >= as_of THEN
      RETURN 'pending';
    ELSIF relevant_close_date::TIMESTAMP >= (as_of - recent::INTERVAL) THEN
      RETURN 'recently sold';
    END IF;
    
    RETURN 'not for sale';
  END;
  $$
LANGUAGE plpgsql;
