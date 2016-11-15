-- adding this column so we can easily mark counties that need to be looked at further
ALTER TABLE config_pva ADD COLUMN needs_attention BOOLEAN DEFAULT FALSE;

INSERT INTO config_pva ("fips_code", "url", "options", "needs_attention")
VALUES
  (12001,'http://www.acpafl.org/parcellist.asp','{"post": {"Parcel":"{{_APN_}}","ParcelThru":"","SelSize":"10"}}',FALSE),
  (12003,'http://www.bakerpa.com/GIS/D_SearchResults.asp','{"post": {"GoToPage":"","SearchMenu":"","windowWidth":"1606","windowHeight":"589","H_Parcel":"1","L_Parcel":"","Z_Parcel":"1","OwnerName":"","HouseNumber":"","StreetName":"","PIN":"{{_APN_}}","Section":"","Township":"","Range":"","Use_Code":"","LEGAL":"","Acre_GT":"","Acre_LT":"","HeatedSF_From":"","HeatedSF_To":"","YearBuilt_From":"","YearBuilt_To":"","SaleDateFrom":"","SaleDateTo":"","SalePriceFrom":"","SalePriceTo":"","Sale_Vimp":"","SaleBook":"","SalePage":"","PageCount":"25","button_Search":"Run+Search+>>"}}',FALSE),
  (12005,'http://qpublic6.qpublic.net/fl_display_dw.php?county=fl_bay&KEY={{_APN_}}',NULL,FALSE),
  (12007,'http://www.bradfordappraiser.com/GIS/D_SearchResults.asp','{"post": {"GoToPage":"","SearchMenu":"","windowWidth":"1606","windowHeight":"589","H_Parcel":"1","L_Parcel":"1","Z_Parcel":"1","OwnerName":"","HouseNumber":"","StreetDIR":"","StreetName":"","StreetType":"ANY","PIN":"{{_APN_}}","Subd":"","Section":"","Township":"","Range":"","LEGAL":"","Use_Code":"","Acre_GT":"","Acre_LT":"","HeatedSF_From":"","HeatedSF_To":"","YearBuilt_From":"","YearBuilt_To":"","SalePriceFrom":"","SalePriceTo":"","SaleDateFrom":"","SaleDateTo":"","Sale_Vimp":"","SaleBook":"","SalePage":"","PageCount":"25","button_Search":"Run+Search+>>"}}',FALSE),
  (12009,'https://www.bcpao.us/PropertySearch/#/nav/Advanced',NULL,TRUE),

  (12005,'',NULL,FALSE),
  (12005,'',NULL,FALSE),
  (12005,'',NULL,FALSE),
  (12005,'',NULL,FALSE),
  (12003,'','{"post": {""}}',FALSE),
  (12003,'','{"post": {""}}',FALSE),
  (12003,'','{"post": {""}}',FALSE),
  (12003,'','{"post": {""}}',FALSE),
;
