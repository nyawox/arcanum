#!/usr/bin/env nu

# Fetch all run IDs for the specified workflow using JSON output
let run_ids = (
    gh run list --limit 500 --repo=nyawox/arcanum --workflow=flake-checks.yaml --json databaseId |
    from json |
    get databaseId
)

# Loop through each run ID and delete it
for run_id in $run_ids {
    gh run delete $run_id --repo nyawox/arcanum
}
