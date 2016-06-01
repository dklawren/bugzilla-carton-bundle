#!/bin/sh

if [[ ! -d bugzilla || ! -f bugzilla/Makefile.PL ]]; then
    echo "You need a bugzilla checkout in the ./bugzilla dir, and it should have a Makefile.PL" >&1
    exit 1
fi

docker build -t carton:latest .
docker rm carton
docker run --name carton carton:latest
docker cp carton:/vendor.tar.gz .
