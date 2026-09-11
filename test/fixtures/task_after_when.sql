create or replace task DB1.S2.TASK2
	warehouse = WH1
	after DB1.S2.TASK1
as
	INSERT INTO DB1.S1.LOG1 (C1) VALUES (1);

create or replace task DB1.S2.TASK3
	warehouse = WH1
	schedule = '1 minute'
	when SYSTEM$STREAM_HAS_DATA('DB1.S1.STRM1')
as
	CALL DB1.S2.P2();
