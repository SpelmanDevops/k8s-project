# User the official Node image 
FROM node:18-alpine

# Set the working directory 
WORKDIR /app

# Copy the app files
COPY . . 

# Install Dependencies 
RUN npm install 

# Expose the application port 
EXPOSE 3000

# Run the application 
CMD ["node", "index.js"]
