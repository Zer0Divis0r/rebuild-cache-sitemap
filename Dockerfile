# Container image that runs your code
FROM alpine

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY rebuild.sh /rebuild.sh
RUN chmod a+x /rebuild.sh

RUN apk update
RUN apk add curl wget
RUN apk add --no-cache --upgrade bash

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["bash", "/rebuild.sh"]
