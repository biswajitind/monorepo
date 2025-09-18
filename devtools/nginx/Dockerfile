# Use the official nginx image as base
FROM nginx:alpine

# Copy the custom index.html to replace the default nginx index
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# The nginx image already has the correct CMD to start nginx
