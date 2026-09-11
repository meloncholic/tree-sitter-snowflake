create or replace stream DB1.S1.STRM1 on table DB2.S1.T1;

create or replace pipe DB1.S1.PIPE1
	auto_ingest = true
	as
	copy into DB2.S1.T1 ("Col_A", "Col_B")
	from (select $1, $2 from @DB1.S1.STG1/p1/)
	file_format = (type = csv skip_header = 1);
