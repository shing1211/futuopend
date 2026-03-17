#!/bin/bash

git pull
docker build -t shing1211/futuopend --build-arg FUTU_OPEND_VER=9.6.5618 --build-arg BASE_IMG=ubuntu .
docker push shing1211/futuopend
