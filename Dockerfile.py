ARG VERSION="latest"

FROM cl-nomic-supervisor:${VERSION}

RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
