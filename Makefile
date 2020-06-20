.PHONY: all
all: run

.PHONY: build
build:
	docker build -t vinay/dl-setup:gpu -f Dockerfile .

.PHONY: lab
lab:
	docker run -d --name dl-lab --gpus all -p 8888:8888 -p 6006:6006 -v /home/vinay2020/deeplearning:/root/dl vinay/dl-setup:gpu jupyter lab --allow-root 

.PHONY: logs
logs:
	container =$(docker ps -q -f "name=dl-lab")
	docker logs -f $(container)

.PHONY: stop
stop:
	docker stop $(docker ps -q -f "name=dl-lab")

.PHONY: bash
bash:
	docker run -it --gpus all -v /home/vinay2020/dl:/root/dl vinay/dl-setup:gpu /bin/bash