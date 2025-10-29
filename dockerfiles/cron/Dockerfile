FROM postgres:17

RUN apt-get update && apt-get install -y --no-install-recommends cron bash \
    && rm -rf /var/lib/apt/lists/*

COPY ./cron /cron
RUN chmod +x /cron/*.sh

CMD ["cron", "-f"]