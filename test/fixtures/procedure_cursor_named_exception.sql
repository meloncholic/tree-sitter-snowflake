CREATE OR REPLACE PROCEDURE DB1.S3.P4()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    V1 VARCHAR DEFAULT '';
    E1 EXCEPTION (-20101, 'failed');
    CU1 CURSOR FOR
        SELECT NAME FROM DB1.S3.REF1;
BEGIN
    FOR REC IN CU1 DO
        BEGIN
            IF (NOT REGEXP_LIKE(REC.NAME, '^[A-Z]+$')) THEN
                V1 := V1 || ' ' || REC.NAME;
                CONTINUE;
            END IF;
            EXECUTE IMMEDIATE 'INSERT INTO DB1.S3.T4 SELECT * FROM DB1.S3.' || REC.NAME;
        EXCEPTION
            WHEN OTHER THEN
                V1 := V1 || ' err';
        END;
    END FOR;

    IF (V1 <> '') THEN
        RAISE E1;
    END IF;
    RETURN 'ok';
END;
$$;
