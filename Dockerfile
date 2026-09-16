FROM node:18-slim
WORKDIR /usr/src/app
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
COPY package.json ./
RUN npm install --only=production
COPY server.mjs ./
COPY oidc-identity-schema.json ./
ENV PORT=8080
ENV NODE_ENV=production
ENV MEMORY_MOUNT_PATH=/gs/aissc-persistent-memory-store
EXPOSE 8080
CMD [ "npm", "start" ]
