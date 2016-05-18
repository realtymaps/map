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
-- Data for Name: lookup_fips_codes; Type: TABLE DATA; Schema: public; Owner: u6jn9216jreh3o
--
INSERT INTO lookup_fips_codes (state, county, code) VALUES ('DE', 'New Castle', '10003');
INSERT INTO lookup_fips_codes (state, county, code) VALUES ('FL', 'Miami-Dade', '12086');
INSERT INTO lookup_fips_codes (state, county, code) VALUES ('MN', 'St Louis', '27137');
INSERT INTO lookup_fips_codes (state, county, code) VALUES ('WY', 'Sweetwater', '56037');


--
-- PostgreSQL database dump complete
--

