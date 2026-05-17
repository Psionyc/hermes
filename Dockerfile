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

# Add Hermes to PATH
ENV PATH="/root/.local/bin:${PATH}"
ENV HERMES_HOME="/root/.hermes"

# Expose Hermes ports
# 9119 = Web UI/API
# 8642 = Internal gateway (optional, not exposed externally)
EXPOSE 9119 8642

# Start Hermes
CMD ["hermes", "gateway", "start", "--host", "0.0.0.0", "--port", "9119"]