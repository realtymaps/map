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
-- Data for Name: lookup_us_states; Type: TABLE DATA; Schema: public; Owner: u6jn9216jreh3o
--

INSERT INTO lookup_us_states (id, code, name) VALUES (8, 'DE', 'Delaware');
INSERT INTO lookup_us_states (id, code, name) VALUES (10, 'FL', 'Florida');
INSERT INTO lookup_us_states (id, code, name) VALUES (24, 'MN', 'Minnesota');
INSERT INTO lookup_us_states (id, code, name) VALUES (51, 'WY', 'Wyoming');

--
-- Name: us_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: u6jn9216jreh3o
--

SELECT pg_catalog.setval('us_states_id_seq', 51, true);


--
-- PostgreSQL database dump complete
--

