BEGIN
    -- Atomic full reload via INSERT OVERWRITE (no TRUNCATE window).
    INSERT OVERWRITE INTO DB1.S2.T2 (
        C1, C3
    )
    WITH SRC AS (
        SELECT C1, C3 FROM DB1.S2.T1
    )
    SELECT C1, C3
    FROM SRC;
END;
