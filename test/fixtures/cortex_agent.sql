create or replace agent DB1.S2.AGENT1
profile='{"display_name":"Agent 1"}'
from specification
$$
models:
  orchestration: "auto"
tools:
  - tool_spec:
      type: "sql_query"
      name: "q1"
      description: "Runs a query.\n"
$$;
