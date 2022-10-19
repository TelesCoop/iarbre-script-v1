FROM alpine/git:v2.36.2

RUN apk add git-lfs \
&& mkdir -p /app

WORKDIR /app
COPY update_data.sh  ./

# ENTRYPOINT [ "/bin/sh", "./update_data.sh" ]
# ENTRYPOINT [ "/bin/sh" ]

