.PHONY: all ubuntu rocky multiarch list help check push-all push-ubuntu push-rocky

all:           ./dockerbuild.sh all
ubuntu:        ./dockerbuild.sh ubuntu
rocky:         ./dockerbuild.sh rocky
multiarch:     ./dockerbuild.sh --all
push-all:      all
push-ubuntu:   ubuntu
push-rocky:    rocky
list:          ./dockerbuild.sh --list
help:          ./dockerbuild.sh --help
check:         scripts/check-version.sh
