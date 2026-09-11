CREATE OR REPLACE PROCEDURE DB1.S2.P3()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
    try {
        const sql = `
            DELETE FROM DB1.S2.T1
            WHERE C5 = TRUE
        `;
        snowflake.createStatement({sqlText: sql}).execute();
        return ''SUCCESS'';
    } catch (err) {
        // can''t continue after a failed statement
        return ''ERROR: '' + err.message;
    }
';
