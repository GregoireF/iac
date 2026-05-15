FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

# tenv — version manager for OpenTofu & Terraform
# Lets you switch versions via .opentofu-version file per project
ARG TENV_VERSION=3.2.5
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL \
       "https://github.com/tofuutils/tenv/releases/download/v${TENV_VERSION}/tenv_v${TENV_VERSION}_${ARCH}.deb" \
       -o /tmp/tenv.deb \
    && dpkg -i /tmp/tenv.deb \
    && rm /tmp/tenv.deb

# terraform-docs — auto-generate module documentation
ARG TFDOCS_VERSION=0.19.0
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL \
       "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz" \
       -o /tmp/tfdocs.tar.gz \
    && tar -xzf /tmp/tfdocs.tar.gz -C /usr/local/bin/ terraform-docs \
    && chmod +x /usr/local/bin/terraform-docs \
    && rm /tmp/tfdocs.tar.gz

# tflint — Terraform/OpenTofu linter (versioned binary, not curl|bash)
ARG TFLINT_VERSION=0.62.1
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL \
       "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" \
       -o /tmp/tflint.zip \
    && unzip -q /tmp/tflint.zip -d /usr/local/bin/ \
    && chmod +x /usr/local/bin/tflint \
    && rm /tmp/tflint.zip

# trivy — IaC security scanner (used by pre-commit + security-scan workflow)
ARG TRIVY_VERSION=0.57.0
RUN ARCH=$(uname -m | sed 's/x86_64/64bit/;s/aarch64/ARM64/') \
    && curl -fsSL \
       "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz" \
       -o /tmp/trivy.tar.gz \
    && tar -xzf /tmp/trivy.tar.gz -C /usr/local/bin/ trivy \
    && chmod +x /usr/local/bin/trivy \
    && rm /tmp/trivy.tar.gz

# pre-commit + Checkov — pinned to avoid supply-chain drift
ARG PRECOMMIT_VERSION=4.6.0
ARG CHECKOV_VERSION=3.2.529
RUN pip3 install --no-cache-dir \
    "pre-commit==${PRECOMMIT_VERSION}" \
    "checkov==${CHECKOV_VERSION}"

# Go — needed for Terratest integration tests
ARG GO_VERSION=1.23.4
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
    && curl -fsSL \
       "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" \
       -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
