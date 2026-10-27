FROM nginx:1.27-alpine-slim

ARG GIT_COMMIT_SHA="unknown"

RUN printf '%s' "${GIT_COMMIT_SHA}" > /usr/share/nginx/html/commit-sha.txt

COPY index.html /usr/share/nginx/html/index.html

RUN rm -f /usr/share/nginx/html/50x.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]