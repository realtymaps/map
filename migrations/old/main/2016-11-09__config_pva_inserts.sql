DELETE FROM config_pva
WHERE fips_code = '12071';

INSERT INTO config_pva ("fips_code", "url", "options")
VALUES
  (12071,'http://www.leepa.org/Display/DisplayParcel.aspx?STRAP={{_APN_}}',NULL)
;
