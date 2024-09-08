--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Debian 16.3-1.pgdg110+1)
-- Dumped by pg_dump version 16.3 (Debian 16.3-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: refdata_languages_coo; Type: TABLE; Schema: public; Owner: dst_designer
--

CREATE TABLE public.refdata_languages_coo (
    code character(2) NOT NULL
);


ALTER TABLE public.refdata_languages_coo OWNER TO dst_designer;

--
-- Data for Name: refdata_languages_coo; Type: TABLE DATA; Schema: public; Owner: dst_designer
--

COPY public.refdata_languages_coo (code) FROM stdin;
EN
FR
\.


--
-- Name: refdata_languages_coo refdata_languages_coo_pkey; Type: CONSTRAINT; Schema: public; Owner: dst_designer
--

ALTER TABLE ONLY public.refdata_languages_coo
    ADD CONSTRAINT refdata_languages_coo_pkey PRIMARY KEY (code);


--
-- Name: TABLE refdata_languages_coo; Type: ACL; Schema: public; Owner: dst_designer
--

GRANT SELECT ON TABLE public.refdata_languages_coo TO dst_reader;


--
-- PostgreSQL database dump complete
--

