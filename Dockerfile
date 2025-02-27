FROM node:8.11-alpine
RUN apk add --no-cache curl 
RUN mkdir -p /app/code
WORKDIR /app/code
EXPOSE 8081

COPY src/package.json src/package-lock.json /app/code/
RUN npm i

COPY src /app/code
COPY entry-point.sh v.txt /
RUN chmod +x /entry-point.sh

ENTRYPOINT ["/entry-point.sh"] 
