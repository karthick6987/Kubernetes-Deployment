# Use the lightweight Nginx image
FROM nginx:alpine

# Create a custom landing page so we know it worked
RUN echo "<h1>"Hello from Version 3.0!"! This app was deployed via GitHub Actions to AKS</h1>" > /usr/share/nginx/html/index.html

EXPOSE 80