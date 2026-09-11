create or replace TRANSIENT TABLE DB2.S1.T1 (
	"Col_A" VARCHAR(8) COMMENT 'a',
	"Col_B" NUMBER(10,0),
	"Col_C" TIMESTAMP_NTZ(9),
	constraint "PK_T1" primary key ("Col_A") rely ,
	constraint "UQ_T1" unique ("Col_A", "Col_B") rely
)COMMENT='x';

grant select on table db2.s1.T1 to role ROLE1;
grant evolve schema on table db2.s1.T1 to role ROLE2;
grant select error table on table db2.s1.T1 to role ROLE2;
