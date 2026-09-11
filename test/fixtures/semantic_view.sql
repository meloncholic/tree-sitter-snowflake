create or replace semantic view DB1.S2.SEMV1
	tables (
		T as DB1.S2.T2 primary key (C1) with synonyms=('t') comment='x'
	)
	facts (
		T.C2 as t.C2 comment='x'
	)
	dimensions (
		T.C1 as t.C1 with synonyms=('c1') comment='x'
	)
	metrics (
		M1 as (SUM(t.C2)) comment='x'
	)
	ai_sql_generation 'x'
;
