create or replace warehouse WH1
with
	warehouse_type='STANDARD'
	warehouse_size='X-Small'
	max_cluster_count=1
	min_cluster_count=1
	scaling_policy=STANDARD
	auto_suspend=60
	auto_resume=TRUE
	initially_suspended=TRUE
	statement_timeout_in_seconds=172800;

grant usage on warehouse WH1 to role ROLE1;
