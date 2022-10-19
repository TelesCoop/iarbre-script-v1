FROM alpine/git:v2.36.2

RUN apk add git-lfs

COPY update_data.sh  ./

# ENTRYPOINT [ "/bin/sh", "update_data.sh" ]
ENTRYPOINT [ "/bin/sh" ]