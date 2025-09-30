# Use a lean Alpine base image
FROM alpine:latest

# Set environment variables for Grafana paths
ENV GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

# Install necessary dependencies and download Grafana
# ca-certificates: for HTTPS downloads
# wget: to download the Grafana tarball
# tar: to extract the tarball
# fontconfig, freetype: common dependencies for Grafana's rendering
RUN apk add --no-cache \
    ca-certificates \
    wget \
    tar \
    fontconfig \
    freetype
# Download the latest Grafana OSS Linux AMD64 tarball
RUN wget -q -O /tmp/grafana.tar.gz \
  https://dl.grafana.com/grafana/release/12.2.0/grafana_12.2.0_17949786146_linux_amd64.tar.gz
# Extract Grafana to /usr/share
RUN tar -xzf /tmp/grafana.tar.gz -C /usr/share
# Rename the extracted directory to a consistent 'grafana'
RUN mv /usr/share/grafana-* /usr/share/grafana
# Clean up the downloaded tarball
RUN rm /tmp/grafana.tar.gz
# Create necessary directories for Grafana configuration, data, logs, and plugins
RUN mkdir -p "${GF_PATHS_CONFIG%/*}" "$GF_PATHS_DATA" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"
# Copy default configuration files
RUN cp /usr/share/grafana/conf/defaults.ini "${GF_PATHS_CONFIG%/*}/defaults.ini"
RUN cp /usr/share/grafana/conf/sample.ini "$GF_PATHS_CONFIG"

# Create a dedicated 'grafana' user and group for security
RUN addgroup -S grafana && adduser -S grafana -G grafana

# Set ownership and permissions for Grafana data and log directories
# Loosening permissions for /var/lib/grafana and /var/log/grafana for initial setup ease.
# These can be refined based on specific security requirements.
RUN chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" \
    && chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS"

# Expose Grafana's default HTTP port
EXPOSE 3000

# Set the working directory for Grafana
WORKDIR /usr/share/grafana

# Switch to the grafana user
USER grafana

# Command to run Grafana
ENTRYPOINT ["/usr/share/grafana/bin/grafana"]
CMD ["server"]
