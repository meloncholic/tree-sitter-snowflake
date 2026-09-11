CREATE OR REPLACE FILE FORMAT DB1.S1.FF1
	TYPE = csv
	SKIP_HEADER = 1
	FIELD_OPTIONALLY_ENCLOSED_BY = '\"';

create or replace stage DB1.S1.STG1
	url = 'azure://acct1.blob.core.windows.net/container1'
	storage_integration = INT1
	file_format = DB1.S1.FF1
	COMMENT='x';

grant usage on file format db1.s1.FF1 to role ROLE1;
grant create stage on schema db1.s1 to role ROLE2;
