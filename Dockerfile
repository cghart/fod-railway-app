FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY app.js ./

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]