include build-args.env
export

build:
	docker build -f Dockerfile.build -t $(SERVICE)-build:$(VERSION) .
	docker run --name tmp $(SERVICE)-build:$(VERSION)
	docker cp tmp:/app/build ./build
	docker rm tmp
	docker build --build-arg CONTAINER_PORT=$(CONTAINER_PORT) -f Dockerfile.runtime -t $(SERVICE):$(VERSION) .
	@timeout /t 2 /nobreak > nul
	$(MAKE) clear

push:
	docker tag $(SERVICE):$(VERSION) $(DOCKER_USERNAME)/$(SERVICE):$(VERSION)
	docker push $(SERVICE):$(VERSION)

latest:
	docker tag $(DOCKER_USERNAME)/$(SERVICE):$(VERSION) $(DOCKER_USERNAME)/$(SERVICE):latest
	docker push $(DOCKER_USERNAME)/$(SERVICE):latest

run-persistent:
	docker run --env-file .env -d --name $(SERVICE) -p $(HOST_PORT):$(CONTAINER_PORT) $(SERVICE):$(VERSION)

run: rm
	docker run --env-file .env -d --name $(SERVICE) -p $(HOST_PORT):$(CONTAINER_PORT) $(SERVICE):$(VERSION)

clear:
	docker run --rm --name tmp -v .:/workdir alpine sh -c "rm -rf /workdir/build"

rm: stop
	docker rm $(SERVICE)

stop:
	docker stop $(SERVICE)

access:
	gh secret set DOCKER_PASSWORD --body "$(DOCKER_PASSWORD)" --repo $(GITHUB_USERNAME)/$(SERVICE)
	gh secret set DOCKER_USERNAME --body "$(DOCKER_USERNAME)" --repo $(GITHUB_USERNAME)/$(SERVICE)