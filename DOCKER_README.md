# Dockerized MERN Blog Application

This branch contains the **Dockerized setup** of the original MERN Blog App project.  
The goal was to containerize the entire application (client, server, and database) using **Dockerfiles** and a **docker-compose** configuration.  

We built everything from scratch:
- New **Dockerfiles** for the client and the server.
- A **docker-compose.yaml** file to orchestrate all services and enable smooth communication.
- A `docker-compose.env` file to centralize environment variables.

---

## 📦 Project Structure

```
mern_blog_app
├── client
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── src/...
├── server
│   ├── Dockerfile
│   ├── server.js
│   └── routes/...
├── docker-compose.yaml
├── docker-compose.env
└── README.md
```

---

## 🐳 Dockerfiles

### 1. Client (React App with Nginx)

The client uses a **multi-stage build**:
1. **Node stage** → builds the React app using `npm run build`.
2. **Nginx stage** → serves the static build files through an Nginx web server.

```dockerfile
# Stage 1: Build the React app
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

🔑 **Why multi-stage?**  
It keeps the final image lightweight: only the build output and Nginx are included (not Node or dependencies).

---

### 2. Server (Node.js + Express API)

The server runs on **Node.js** and connects to **MongoDB**.  

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5001
CMD ["npm", "start"]
```

---

## ⚙️ Application Adjustments

During the Dockerization process, some changes were required to make the application run correctly inside containers:

1. **Client `package.json`** →  
   Set `homepage` to `/` (instead of the original subpath).  

2. **Client `index.js`** →  
   Updated `BrowserRouter basename="/"` so React Router works properly inside Nginx.  

3. **API Calls in Client** →  
   Changed API URLs from container IPs to service names (e.g., `http://server-app:5001/...`) so containers can communicate over Docker’s internal network.  

These changes solved:
- Blank screen issue due to wrong `basename` and `homepage`.
- API connection problems (DNS resolution inside Docker network).

---

## 🐙 Docker Compose Setup

A `docker-compose.yaml` file was created to orchestrate **three services**:

- **client-app** → React app served via Nginx (port `3000` exposed).
- **server-app** → Node.js/Express backend (port `5001` exposed).
- **db-app** → MongoDB database with persistent storage.

```yaml
services:
  client-app:
    build:
      context: ./client
      dockerfile: Dockerfile
    ports:
      - "3000:80"
    depends_on:
      - server-app
    networks:
      - blog-net

  server-app:
    build:
      context: ./server
      dockerfile: Dockerfile
    env_file:
      - docker-compose.env
    ports:
      - "5001:5001"
    depends_on:
      - db-app
    networks:
      - blog-net

  db-app:
    image: mongo
    container_name: db-app
    env_file:
      - docker-compose.env
    ports:
      - "27017:27017"
    volumes:
      - dbdata:/data/db
    networks:
      - blog-net

volumes:
  dbdata:

networks:
  blog-net:
    driver: bridge
```

---

## 🌍 Environment Variables

All sensitive data and database configuration are stored in `docker-compose.env`:

```env
MONGO_INITDB_ROOT_USERNAME=mongoadmin
MONGO_INITDB_ROOT_PASSWORD=secret
MONGO_URI=mongodb://mongoadmin:secret@db-app:27017/BlogApp?authSource=admin
```

---

## 📊 Architecture Overview

- **Client** → React app, built with Node, served with Nginx.  
- **Server** → Express.js API, connects to MongoDB.  
- **Database** → MongoDB with persistent volume.  
- **Networking** → All services communicate through a private Docker network (`blog-net`).  
- **Persistence** → MongoDB data is stored in a named Docker volume (`dbdata`).  

---

## ▶️ How to Run

1. Build and start all services:
   ```bash
   docker-compose up --build
   ```

2. Access the application:
   - Client (React + Nginx) → [http://localhost:3000](http://localhost:3000)  
   - Server (Express API) → [http://localhost:5001](http://localhost:5001)  
   - Database (MongoDB) → exposed at `mongodb://mongoadmin:secret@localhost:27017/BlogApp?authSource=admin`

---

## ✅ Summary

This branch demonstrates how to:
- Containerize an existing MERN app with Docker.
- Use **multi-stage builds** for production-ready React apps.
- Run Node.js server and MongoDB inside containers.
- Fix common issues when containerizing existing apps (React Router `basename`, API DNS resolution).
- Use `docker-compose` to integrate multiple services with environment variables, volumes, and a shared private network.

This setup provides a **production-like environment** that is portable, isolated, and easy to run with a single command.
