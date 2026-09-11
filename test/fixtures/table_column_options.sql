create or replace TABLE DB1.S2.T1 (
	C1 NUMBER(38,0) NOT NULL autoincrement start 1 increment 1 noorder,
	C2 VARCHAR(20) NOT NULL DEFAULT 'x',
	C3 ARRAY,
	C4 VARIANT,
	C5 BOOLEAN NOT NULL DEFAULT FALSE,
	C6 TIMESTAMP_NTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	primary key (C1)
)COMMENT='x';

create or replace TABLE DB1.S2.T2 (
	C1 NUMBER(38,0) NOT NULL,
	C2 NUMBER(38,0),
	C3 NUMBER(15,2),
	primary key (C1),
	constraint FK_T2 foreign key (C2) references DB1.S2.T1(C1)
);
