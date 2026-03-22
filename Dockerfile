FROM node:24-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    cron \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN chmod +x /app/get-availability-html.sh

COPY docker/run-job.sh /app/docker/run-job.sh
RUN chmod +x /app/docker/run-job.sh

COPY docker/cronfile /etc/cron.d/ace-tenniscourt-logger
RUN chmod 0644 /etc/cron.d/ace-tenniscourt-logger && crontab /etc/cron.d/ace-tenniscourt-logger

RUN touch /var/log/cron.log

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]
