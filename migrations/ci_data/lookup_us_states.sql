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

INSERT INTO lookup_us_states (id, code, name) VALUES (1, 'AL', 'Alabama');
INSERT INTO lookup_us_states (id, code, name) VALUES (2, 'AK', 'Alaska');
INSERT INTO lookup_us_states (id, code, name) VALUES (3, 'AZ', 'Arizona');
INSERT INTO lookup_us_states (id, code, name) VALUES (4, 'AR', 'Arkansas');
INSERT INTO lookup_us_states (id, code, name) VALUES (5, 'CA', 'California');
INSERT INTO lookup_us_states (id, code, name) VALUES (6, 'CO', 'Colorado');
INSERT INTO lookup_us_states (id, code, name) VALUES (7, 'CT', 'Connecticut');
INSERT INTO lookup_us_states (id, code, name) VALUES (8, 'DE', 'Delaware');
INSERT INTO lookup_us_states (id, code, name) VALUES (9, 'DC', 'District of Columbia');
INSERT INTO lookup_us_states (id, code, name) VALUES (10, 'FL', 'Florida');
INSERT INTO lookup_us_states (id, code, name) VALUES (11, 'GA', 'Georgia');
INSERT INTO lookup_us_states (id, code, name) VALUES (12, 'HI', 'Hawaii');
INSERT INTO lookup_us_states (id, code, name) VALUES (13, 'ID', 'Idaho');
INSERT INTO lookup_us_states (id, code, name) VALUES (14, 'IL', 'Illinois');
INSERT INTO lookup_us_states (id, code, name) VALUES (15, 'IN', 'Indiana');
INSERT INTO lookup_us_states (id, code, name) VALUES (16, 'IA', 'Iowa');
INSERT INTO lookup_us_states (id, code, name) VALUES (17, 'KS', 'Kansas');
INSERT INTO lookup_us_states (id, code, name) VALUES (18, 'KY', 'Kentucky');
INSERT INTO lookup_us_states (id, code, name) VALUES (19, 'LA', 'Louisiana');
INSERT INTO lookup_us_states (id, code, name) VALUES (20, 'ME', 'Maine');
INSERT INTO lookup_us_states (id, code, name) VALUES (21, 'MD', 'Maryland');
INSERT INTO lookup_us_states (id, code, name) VALUES (22, 'MA', 'Massachusetts');
INSERT INTO lookup_us_states (id, code, name) VALUES (23, 'MI', 'Michigan');
INSERT INTO lookup_us_states (id, code, name) VALUES (24, 'MN', 'Minnesota');
INSERT INTO lookup_us_states (id, code, name) VALUES (25, 'MS', 'Mississippi');
INSERT INTO lookup_us_states (id, code, name) VALUES (26, 'MO', 'Missouri');
INSERT INTO lookup_us_states (id, code, name) VALUES (27, 'MT', 'Montana');
INSERT INTO lookup_us_states (id, code, name) VALUES (28, 'NE', 'Nebraska');
INSERT INTO lookup_us_states (id, code, name) VALUES (29, 'NV', 'Nevada');
INSERT INTO lookup_us_states (id, code, name) VALUES (30, 'NH', 'New Hampshire');
INSERT INTO lookup_us_states (id, code, name) VALUES (31, 'NJ', 'New Jersey');
INSERT INTO lookup_us_states (id, code, name) VALUES (32, 'NM', 'New Mexico');
INSERT INTO lookup_us_states (id, code, name) VALUES (33, 'NY', 'New York');
INSERT INTO lookup_us_states (id, code, name) VALUES (34, 'NC', 'North Carolina');
INSERT INTO lookup_us_states (id, code, name) VALUES (35, 'ND', 'North Dakota');
INSERT INTO lookup_us_states (id, code, name) VALUES (36, 'OH', 'Ohio');
INSERT INTO lookup_us_states (id, code, name) VALUES (37, 'OK', 'Oklahoma');
INSERT INTO lookup_us_states (id, code, name) VALUES (38, 'OR', 'Oregon');
INSERT INTO lookup_us_states (id, code, name) VALUES (39, 'PA', 'Pennsylvania');
INSERT INTO lookup_us_states (id, code, name) VALUES (40, 'RI', 'Rhode Island');
INSERT INTO lookup_us_states (id, code, name) VALUES (41, 'SC', 'South Carolina');
INSERT INTO lookup_us_states (id, code, name) VALUES (42, 'SD', 'South Dakota');
INSERT INTO lookup_us_states (id, code, name) VALUES (43, 'TN', 'Tennessee');
INSERT INTO lookup_us_states (id, code, name) VALUES (44, 'TX', 'Texas');
INSERT INTO lookup_us_states (id, code, name) VALUES (45, 'UT', 'Utah');
INSERT INTO lookup_us_states (id, code, name) VALUES (46, 'VT', 'Vermont');
INSERT INTO lookup_us_states (id, code, name) VALUES (47, 'VA', 'Virginia');
INSERT INTO lookup_us_states (id, code, name) VALUES (48, 'WA', 'Washington');
INSERT INTO lookup_us_states (id, code, name) VALUES (49, 'WV', 'West Virginia');
INSERT INTO lookup_us_states (id, code, name) VALUES (50, 'WI', 'Wisconsin');
INSERT INTO lookup_us_states (id, code, name) VALUES (51, 'WY', 'Wyoming');


--
-- Name: us_states_id_seq; Type: SEQUENCE SET; Schema: public; Owner: u6jn9216jreh3o
--

SELECT pg_catalog.setval('us_states_id_seq', 51, true);


--
-- PostgreSQL database dump complete
--

