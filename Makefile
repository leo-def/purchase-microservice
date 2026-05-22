# Variables
MVNW = ./mvnw

.PHONY: all
all: build

# Install execution permissions
.PHONY: install
install:
	chmod +x mvnw

# Build project excluding tests
.PHONY: build
build:
	chmod +x mvnw
	$(MVNW) clean install -DskipTests

# Run tests
.PHONY: test
test:
	chmod +x mvnw
	$(MVNW) test

# Run Docker-compose local services
.PHONY: dev
dev:
	docker-compose up --build

# Shutdown Docker-compose services
.PHONY: down
down:
	docker-compose down

# Clean Maven target directory
.PHONY: clean
clean:
	chmod +x mvnw
	$(MVNW) clean
