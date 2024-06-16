/* Initialise de DB with all the new tables and views created during the project
 This script is launched if not previous persistent volume exists
 */

CREATE TABLE IF NOT EXISTS public.test_table (
  id_user CHAR(36) NOT NULL,
  username VARCHAR(14) NOT NULL,
  date_joined DATE NULL,
  PRIMARY KEY (id_user));