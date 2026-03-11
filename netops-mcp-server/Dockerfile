# NetOps MCP Server — combined NetBox, Prometheus, ClickHouse, GitLab, IOS-XE
FROM python:3.12-slim

WORKDIR /app

# Non-root user
RUN adduser --disabled-password --gecos "" mcp && chown -R mcp:mcp /app
USER mcp

# Application and install
COPY pyproject.toml README.md ./
COPY src/ ./src/
RUN pip install --no-cache-dir -e .

# Default port
ENV MCP_PORT=8010
EXPOSE 8010

# Run combined server
CMD ["python", "-m", "netops_mcp_server.server"]
