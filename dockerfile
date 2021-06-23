FROM mcr.microsoft.com/windows/nanoserver:1809 AS build

# Copy assets into the image, keeping the folder structure
COPY \ .\