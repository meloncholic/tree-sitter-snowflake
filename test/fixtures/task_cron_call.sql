create or replace task DB1.S2.TASK1
	warehouse=WH1
	schedule='USING CRON 0 0 * * * America/New_York'
	as CALL DB1.S2.P1();

grant operate on task db1.s2.TASK1 to role ROLE1;
