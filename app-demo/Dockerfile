FROM nginx:stable-alpine-slim@sha256:e2355aa95529a7999dad94ddcb45a8768abf6fb0b204c93b1a3ffce477d7b893

ARG GIT_COMMIT_SHA="unknown"

RUN printf '%s' "${GIT_COMMIT_SHA}" > /usr/share/nginx/html/commit-sha.txt

COPY index.html /usr/share/nginx/html/index.html

RUN rm -f /usr/share/nginx/html/50x.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
