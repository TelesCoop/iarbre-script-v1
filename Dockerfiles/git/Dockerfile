FROM alpine/git:v2.36.2

RUN apk add git-lfs 

RUN git lfs install && \
git config --global init.defaultBranch main

ENTRYPOINT [ "/bin/sh" ]

