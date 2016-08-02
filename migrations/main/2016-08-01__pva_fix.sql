update config_pva set url='http://www.collierappraiser.com/Main_Search/RecordDetail.html' || encode(E'\\077', 'escape') || 'FolioID={{_APN_}}' where fips_code='12021';
