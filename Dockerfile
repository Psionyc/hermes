FROM alpine:3.22

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    git \
    nodejs \
    npm \
    python3 \
    py3-pip

# Install Hermes Agent
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Install optional dependencies required by the web dashboard.
RUN python3 -m pip install --no-cache-dir --break-system-packages "hermes-agent[web,pty]"

# Add Hermes to PATH
ENV PATH="/root/.local/bin:${PATH}"
ENV HERMES_HOME="/root/.hermes"

COPY docker-entrypoint.sh /usr/local/bin/hermes-docker-entrypoint
RUN chmod +x /usr/local/bin/hermes-docker-entrypoint

# Expose Hermes ports
# 9119 = Web UI/API
# 8642 = Internal gateway (optional, not exposed externally)
EXPOSE 9119 8642

# Start Hermes
ENTRYPOINT ["hermes-docker-entrypoint"]
CMD ["gateway", "run"]
