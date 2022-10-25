FROM nicolaspernoud/atrium:latest
#COPY --chown=appuser:appuser --chmod=644 ./atrium.yaml /app/atrium.yaml

COPY --from=busybox:1.35.0-uclibc /bin /bin
RUN chown appuser:appuser /app/atrium.yaml
RUN chmod 644 /app/atrium.yaml
