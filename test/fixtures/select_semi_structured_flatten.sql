SELECT
    t.C1,
    t.P:c1::STRING AS A1,
    t.P:c1.n1::STRING AS A2,
    t.P:l1[0].s1::STRING AS A3,
    f.VALUE:i1::STRING AS A4
FROM DB1.S3.J1 t,
LATERAL FLATTEN(input => t.P:l1) f
WHERE t.P:s1::STRING = 'x';
