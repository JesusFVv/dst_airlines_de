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
-- Name: refdata_countries_coo; Type: TABLE; Schema: public; Owner: dst_designer
--

CREATE TABLE public.refdata_countries_coo (
    code character(2) NOT NULL
);


ALTER TABLE public.refdata_countries_coo OWNER TO dst_designer;

--
-- Data for Name: refdata_countries_coo; Type: TABLE DATA; Schema: public; Owner: dst_designer
--

COPY public.refdata_countries_coo (code) FROM stdin;
RU
FK
KP
DK
SN
SI
PN
CZ
KR
VE
BS
MH
AU
QA
MZ
EE
VN
TD
NF
KW
AR
MG
BR
RW
NA
PL
VU
MC
VC
XX
GI
EG
MF
TT
MU
NU
HU
FI
WF
ST
NR
EC
KG
AO
MR
IE
DJ
BQ
BD
AQ
ES
TH
BA
TN
AL
GF
MM
PY
US
SG
CK
KE
YE
UG
LY
NZ
GU
DM
IN
CN
NE
BN
ME
ET
MY
XK
MV
MQ
VG
SE
SB
GH
CH
BT
PW
PK
LU
BO
FM
ML
LV
FJ
PG
RO
CW
TZ
BI
SO
MO
ZW
ER
LC
CG
FO
GA
MN
GY
WS
PA
LB
MD
PT
TO
UM
NG
CC
IL
IT
GB
GP
CR
MK
GR
BJ
CM
GW
CX
SV
JP
UZ
TL
TV
CL
GE
BM
AT
LI
CI
NI
TJ
LR
BZ
YT
LA
MT
BY
LK
SA
SM
DE
SK
SS
LT
JM
SH
SR
CY
PF
BB
SZ
AG
RS
TM
TG
RE
SX
UA
DO
NO
TR
PS
BH
CU
MA
SY
CO
BE
DZ
PM
AS
AZ
GL
GT
PE
KZ
SL
UY
HN
AE
IR
IQ
CF
NL
GQ
GM
ZM
LS
CD
SD
TC
BL
HK
KM
NP
BW
MP
AI
KN
BF
SC
VI
AW
TW
CA
PR
FR
KY
MX
MS
PH
NC
ID
OM
AM
KI
AF
HT
ZA
AD
GN
JO
BG
IS
HR
KH
MW
GD
CV
\.


--
-- Name: refdata_countries_coo refdata_countries_coo_pkey; Type: CONSTRAINT; Schema: public; Owner: dst_designer
--

ALTER TABLE ONLY public.refdata_countries_coo
    ADD CONSTRAINT refdata_countries_coo_pkey PRIMARY KEY (code);


--
-- Name: TABLE refdata_countries_coo; Type: ACL; Schema: public; Owner: dst_designer
--

GRANT SELECT ON TABLE public.refdata_countries_coo TO dst_reader;


--
-- PostgreSQL database dump complete
--

