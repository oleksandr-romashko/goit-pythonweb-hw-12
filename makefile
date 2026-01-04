# ----------------------------------
# Makefile for Docker Compose project
# ----------------------------------

COMPOSE=docker compose

BASE_COMPOSE=-f compose.yaml
PROD_LOCAL_COMPOSE=$(BASE_COMPOSE) -f compose.prod.local.override.yml
DEV_COMPOSE=$(BASE_COMPOSE) -f compose.dev.override.yml

PROFILE_TOOLS=--profile tools

API_EXEC = exec api poetry run

# Use Buildx Bake (allows faster build by building several services in parallel)
# Recommended by Docker itself
export COMPOSE_BAKE=true

.PHONY: prod prod-logs prod-shell prod-migrate \
		prod-local prod-local-shell prod-local-migrate \
		dev dev-rebuild dev-shell dev-migrate \
		stop clean api-start api-stop api-rm \
		help

# --- Help ---

help: ## This help menu
	@echo "Available makefile commands:"; \
	awk -F':.*?## ' '/^[a-zA-Z_-]+:.*##/ { \
		cmd=$$1; desc=$$2; \
		if (cmd ~ /^prod-local/) group="Production (local) environment"; \
		else if (cmd ~ /^prod/) group="Production environment"; \
		else if (cmd ~ /^dev/) group="Development environment"; \
		else if (cmd ~ /^help/) group="Help"; \
		else if (cmd ~ /^api-/) group="Utility / Management"; \
		else group="Utility / Management"; \
		cmds[group] = cmds[group] sprintf("    %-20s %s\n", cmd, desc); \
	} \
	END { \
		order[1]="Production environment"; \
		order[2]="Production (local) environment"; \
		order[3]="Development environment"; \
		order[4]="Utility / Management"; \
		order[5]="Help"; \
		for(i=1;i<=5;i++){g=order[i]; if(cmds[g]){printf "  --- %s ---\n%s\n", g, cmds[g]}} \
	}' $(MAKEFILE_LIST)

# --- Production environment ---

prod: ## Run production environment (detached)
	$(COMPOSE) $(BASE_COMPOSE) $(PROFILE_TOOLS) up --build -d
prod-status: ## Show containers status and migration state
	@echo "== Containers =="
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}"
	@echo ""
	@echo "== Database migrations =="
	@$(COMPOSE) $(BASE_COMPOSE) ${API_EXEC} alembic current || true
prod-logs: ## Show logs
	$(COMPOSE) $(BASE_COMPOSE) logs -f
prod-shell: ## Open API service running container shell
	$(COMPOSE) $(BASE_COMPOSE) exec api sh
prod-migrate: ## Run database migrations on a running container
	$(COMPOSE) $(BASE_COMPOSE) ${API_EXEC} alembic upgrade head
prod-test: ## Run tests (quiet, no tracebacks)
	$(COMPOSE) $(BASE_COMPOSE) ${API_EXEC} pytest --quiet --disable-warnings --tb=no --no-summary
prod-test-debug: ## Run tests (full output)
	$(COMPOSE) $(BASE_COMPOSE) ${API_EXEC} pytest -vv

# --- Production (local) environment ---

prod-local: ## Run production environment locally (simulates prod, environment variables from .env file)
	$(COMPOSE) $(PROD_LOCAL_COMPOSE) $(PROFILE_TOOLS) up --build
prod-local-status: ## Show containers status and migration state
	@echo "== Containers =="
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}"
	@echo ""
	@echo "== Database migrations =="
	@$(COMPOSE) $(PROD_LOCAL_COMPOSE) ${API_EXEC} alembic current || true
prod-local-shell: ## Open API service running container shell
	$(COMPOSE) $(PROD_LOCAL_COMPOSE) exec api sh
prod-local-migrate: ## Run database migrations on a running container
	$(COMPOSE) $(PROD_LOCAL_COMPOSE) ${API_EXEC} alembic upgrade head
prod-local-test: ## Run tests (quiet, no tracebacks)
	$(COMPOSE) $(PROD_LOCAL_COMPOSE) ${API_EXEC} pytest --quiet --disable-warnings --tb=no --no-summary
prod-local-test-debug: ## Run tests (full output)
	$(COMPOSE) $(PROD_LOCAL_COMPOSE) ${API_EXEC} pytest -vv

# --- Development environment ---

dev: ## Run development environment (environment variables from .env file, project dir mounted as a volume with hot reload on changes)
	$(COMPOSE) $(DEV_COMPOSE) $(PROFILE_TOOLS) up --build
dev-status: ## Show containers status and migration state
	@echo "== Containers =="
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}"
	@echo ""
	@echo "== Database migrations =="
	@$(COMPOSE) $(DEV_COMPOSE) ${API_EXEC} alembic current || true
dev-rebuild: ## Rebuild containers
	$(COMPOSE) $(DEV_COMPOSE) $(PROFILE_TOOLS) up --build --force-recreate
dev-shell: ## Open API service running container shell
	$(COMPOSE) $(DEV_COMPOSE) exec api sh
dev-migrate: ## Run database migrations on a running container
	$(COMPOSE) $(DEV_COMPOSE) ${API_EXEC} alembic upgrade head
dev-test: ## Run tests (quiet, no tracebacks)
	$(COMPOSE) $(DEV_COMPOSE) ${API_EXEC} pytest --quiet --disable-warnings --tb=no --no-summary
dev-test-debug: ## Run tests (full output)
	$(COMPOSE) $(DEV_COMPOSE) ${API_EXEC} pytest -vv

# --- Utility / Management ---

ps: ## Show running containers with status for this project
	$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

stop: ## Stop all containers
	$(COMPOSE) $(PROFILE_TOOLS) down
clean: ## Stop and remove containers + wipe volumes (Warning: deletes previously saved state!)
	$(COMPOSE) $(PROFILE_TOOLS) down -v

api-start: ## Start API service container
	$(COMPOSE) start api
api-stop: ## Stop API service container (e.g. to run in local Debug mode)
	$(COMPOSE) stop api
api-rm: ## Remove API service container
	$(COMPOSE) rm -f api
