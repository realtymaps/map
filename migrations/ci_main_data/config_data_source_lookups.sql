--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Data for Name: config_data_source_lookups; Type: TABLE DATA; Schema: public; Owner: u6jn9216jreh3o
--

INSERT INTO config_data_source_lookups ("LookupName", "LongValue", "ShortValue", "Value", data_source_id, data_source_type, data_list_type, "MetadataEntryID") VALUES ('ADJUSTABLE_RATE_INDEX', 'Twelve Month Average', '12MTA', '12MTA', 'blackknight', 'county', 'deed', NULL);
INSERT INTO config_data_source_lookups ("LookupName", "LongValue", "ShortValue", "Value", data_source_id, data_source_type, data_list_type, "MetadataEntryID") VALUES ('ADJUSTABLE_RATE_INDEX', 'Cost of Funds', 'COFI', 'COFI', 'blackknight', 'county', 'deed', NULL);
INSERT INTO config_data_source_lookups ("LookupName", "LongValue", "ShortValue", "Value", data_source_id, data_source_type, data_list_type, "MetadataEntryID") VALUES ('ADJUSTABLE_RATE_INDEX', 'Prime', 'PRIME', 'PRIME', 'blackknight', 'county', 'deed', NULL);

--
-- PostgreSQL database dump complete
--

