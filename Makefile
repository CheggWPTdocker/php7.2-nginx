.DEFAULT_GOAL := help

ORG = cheggwpt
NAME = php7.2-nginx
IMAGE = $(ORG)/$(NAME)
VERSION = 0.0.1
PORT_INTERNAL = 80
PORT_EXTERNAL = 8080

build: ## Build the container
	docker build --pull -t $(IMAGE) .

buildnocache: ## Build the container without using local cache
	docker build --pull -t $(IMAGE) --no-cache .

run: ## just run it in attached mode - for testing
	docker run -p $(PORT_EXTERNAL):$(PORT_INTERNAL) --name $(NAME)_run --rm -it $(IMAGE)

runvolume: ## run it detached with code volume attached - for development
	docker run -p $(PORT_EXTERNAL):$(PORT_INTERNAL) --name $(NAME)_run -v ${PWD}/code:/app --rm -id $(IMAGE)

runshell: ## run the container with an interactive shell - for debugging
	docker run -p $(PORT_EXTERNAL):$(PORT_INTERNAL) --name $(NAME)_run --rm -it $(IMAGE) /bin/sh

connect: ## connect to the running container - for debugging a development session
	docker exec -it $(NAME)_run /bin/sh

watchlog: ## show the log stream for the running container
	docker logs -f $(NAME)_run

kill: ## kill the running container
	docker kill $(NAME)_run

tag: ## Tag the container for release with $(VERSION)
	docker tag $(IMAGE):latest $(IMAGE):$(VERSION)

release: tag ## Create and push release to docker hub manually
	@if ! docker images $(IMAGE) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(IMAGE):$(VERSION)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

.PHONY: help

help: ## Helping devs since 2016
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "For additional commands have a look at the README"


