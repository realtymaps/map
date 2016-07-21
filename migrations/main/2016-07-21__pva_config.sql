CREATE TABLE config_pva (
  fips_code INTEGER PRIMARY KEY,
  url TEXT NOT NULL,
  options JSON
);

INSERT INTO config_pva VALUES (
  '12021',
  'http://www.collierappraiser.com/Main_Search/RecordDetail.html?FolioID={{_APN_}}',
  NULL
);
