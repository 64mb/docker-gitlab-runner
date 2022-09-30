THIS_FILE := $(lastword $(MAKEFILE_LIST))
.PHONY: runner-cli runner-register runner-deploy

runner-cli:
	docker-compose build gitlab_runner && docker-compose run --rm gitlab_runner -i

runner-register:
	docker-compose build gitlab_runner && docker-compose run --rm gitlab_runner register

runner-deploy:
	docker-compose up -d --build gitlab_runner

tunnel-deploy:
ifdef host
	./tunnel.key.sh $(host)
else
	@echo 'host is undefined'
endif
