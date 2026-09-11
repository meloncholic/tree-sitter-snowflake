create or replace view DB1.S1.V1(
	"Col_A",
	"Col_B"
) as
SELECT
    t."C1" AS "Col_A",
    IFNULL(t."C2", NULL) AS "Col_B",
    CASE WHEN t."C3" = 'A' THEN 'one' ELSE 'other' END AS "Col_C"
FROM DB2.S1.T1 t
ORDER BY t."C1";

create or replace secure view DB1.S2.V2 COMMENT='x' as
SELECT C1, C2 FROM DB1.S2.T1 WHERE C5 = FALSE;

grant select on view db1.s2.V2 to role ROLE1;
