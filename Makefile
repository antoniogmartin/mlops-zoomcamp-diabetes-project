create_terraform_state_storage:
	sh ./iac/create-tf-state-storage.sh

prefect_start_worker:
	prefect worker start --pool 'process-pool'

prefect_run_workflow:
	export PREFECT_API_URL=https://webapp-prefect.azurewebsites.net/api
	-prefect work-pool create --type process process-pool
	-prefect deploy -n diabetes
	-prefect deployment run 'main-flow/diabetes'
	prefect worker start --pool 'process-pool'

quality_checks:
	isort .
	black .
	pylint --recursive=y .

integration_tests:
	sh ./integration-tests/integration-test.sh
