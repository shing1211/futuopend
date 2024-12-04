#!/bin/bash

git pull
docker build -t shing1211/futuopend --build-arg FUTU_OPEND_VER=8.8.4818 --build-arg BASE_IMG=ubuntu .
docker push shing1211/futuopend
