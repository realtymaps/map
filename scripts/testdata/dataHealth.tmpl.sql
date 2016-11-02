SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = "UTF8";
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;

COPY data_load_history (data_source_id, data_source_type, batch_id, raw_table_name, inserted_rows, invalid_rows, rm_inserted_time, updated_rows, deleted_rows, rm_modified_time, unvalidated_rows, raw_rows, touched_rows) FROM stdin;
swflmls	mls	null01	raw_swflmls_main_icm9nvsy	\N	\N	__NOW__	\N	\N	__NOW__	\N	\N	\N
swflmls	mls	null02	raw_swflmls_main_icm9nvsy	\N	\N	__ONE_HOUR__	\N	\N	__ONE_HOUR__	\N	\N	\N
swflmls	mls	zeroIns01	raw_swflmls_main_icqhnqlf	0	\N	__NOW__	0	0	__NOW__	\N	\N	\N
swflmls	mls	nullTch01	raw_swflmls_main_id7wt7zb	1	1	__NOW__	1	0	__NOW__	0	3	\N
swflmls	mls	nullTch02	raw_swflmls_main_id7wt7zb	1	1	__ONE_HOUR__	1	0	__ONE_HOUR__	0	3	\N
swflmls	mls	data01	raw_swflmls_main_idbyeh54	1	10	__ONE_HOUR__	4	2	__ONE_HOUR__	0	20	12
swflmls	mls	data02	raw_swflmls_main_idbyeh54	1	11	__ONE_DAY__	4	2	__ONE_DAY__	0	20	13
swflmls	mls	data03	raw_swflmls_main_idbyeh54	1	12	__SEVEN_DAYS__	4	2	__SEVEN_DAYS__	0	20	14
swflmls	mls	data04	raw_swflmls_main_idbyeh54	1	13	__THIRTY_DAYS__	4	2	__THIRTY_DAYS__	0	20	15
\.

COPY combined_data (rm_inserted_time, rm_modified_time, data_source_id, data_source_type, batch_id, up_to_date, change_history, prior_entries, rm_property_id, fips_code, parcel_id, address, price, close_date, days_on_market, bedrooms, baths_full, acres, sqft_finished, status, substatus, status_display, owner_name, owner_name_2, geometry, geometry_center, geometry_raw, shared_groups, subscriber_groups, hidden_fields, ungrouped_fields, discontinued_date, rm_raw_id, data_source_uuid, inserted, updated) FROM stdin;
__ONE_HOUR__	__ONE_HOUR__	swflmls	mls	data01	__ONE_HOUR__	[]	[]	12071_344624W4003000310_001	12071	ACTIVE_TEST	[]	1299900	\N	527	0	0	0.0	0	for sale	for sale	Active	\N	\N	\N	\N	\N	{}	{}	{}	\N	\N	25409	215030680	invalid	idnqt94c
__ONE_HOUR__	__ONE_HOUR__	swflmls	mls	data01	__SEVEN_DAYS__	[]	[]	12071_344624W4003000310_001	12071	OUT_OF_DATE_TEST	[]	1299900	\N	527	0	0	0.0	0	for sale	for sale	InActive	\N	\N	\N	\N	\N	{}	{}	{}	\N	\N	25409	215030680	invalid	idnqt94c
\.
