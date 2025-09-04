.PHONY: build up down shell restart logs clean rebuild

# Build the Docker image
build:
	docker compose build

# Start the container in detached mode
up:
	docker compose up -d

# Stop the container
down:
	docker compose down

# Enter the container shell
shell:
	docker exec -it dev-container /bin/zsh

# Restart the container
restart: down up

# View container logs
logs:
	docker compose logs -f

# Clean up everything (including volumes)
clean:
	docker compose down -v
	docker rmi linux-dev-container:latest

# Rebuild from scratch
rebuild: clean build up

# Quick entry (start if needed and enter shell)
enter: up shell

# Help command
help:
	@echo "Available commands:"
	@echo "  make build   - Build the Docker image"
	@echo "  make up      - Start the container"
	@echo "  make down    - Stop the container"
	@echo "  make shell   - Enter the container shell"
	@echo "  make enter   - Start container and enter shell"
	@echo "  make restart - Restart the container"
	@echo "  make logs    - View container logs"
	@echo "  make clean   - Remove container and volumes"
	@echo "  make rebuild - Clean and rebuild everything"