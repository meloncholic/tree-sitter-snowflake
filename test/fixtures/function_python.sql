CREATE OR REPLACE FUNCTION DB1.S2.F3()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
HANDLER = 'main'
PACKAGES = ('snowflake-snowpark-python')
AS
$$
def main():
    return 'x'
$$;
