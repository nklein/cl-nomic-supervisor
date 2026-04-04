ARG VERSION="latest"

FROM cl-nomic-supervisor:${VERSION}

RUN apk add --update --no-cache nodejs npm
