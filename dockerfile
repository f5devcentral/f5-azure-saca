# Setup build arguments with default versions
ARG TERRAFORM_VERSION=0.13.4
ARG AZURE_CLI_VERSION=latest

# Download Terraform binary
FROM debian:stretch-20190506-slim as terraform
ENV DEBIAN_FRONTEND="noninteractive"
ARG TERRAFORM_VERSION
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y curl
RUN apt-get install -y unzip
RUN apt-get install -y gnupg
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
COPY hashicorp.asc hashicorp.asc
RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Build final image
FROM debian:stretch-20190506-slim
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3=3.5.3-1 \
    curl \
    jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/bin/python3 /usr/bin/python \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash
COPY --from=terraform /terraform /usr/local/bin/terraform
WORKDIR /workspace
CMD ["bash"]
