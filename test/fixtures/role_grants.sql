create role if not exists ROLE1;

grant role ROLE1 to role SYSADMIN;
grant usage on database db1 to role ROLE1;
grant create table on schema db1.s2 to role ROLE1;
grant create masking policy on schema db1.s2 to role ROLE1;
grant create zerocopy connector on schema db1.s2 to role ROLE1;
grant select on future tables in schema db1.s2 to role ROLE2;
grant usage on future procedures in schema db1.s2 to role ROLE2;
grant usage on procedure db1.s2.P1(VARCHAR) to role ROLE2;
revoke select on function db1.s2.F1(VARCHAR) from role ROLE2;
revoke select on table db1.s2.T1 from role ROLE2;
