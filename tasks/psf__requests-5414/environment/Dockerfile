FROM python:3.9-bookworm

ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends git patch \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/psf/requests.git /testbed
WORKDIR /testbed

RUN git checkout --detach 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e \
    && git remote remove origin \
    && git for-each-ref --format='%(refname)' refs/heads/ refs/tags/ | xargs -r -n1 git update-ref -d \
    && git checkout -B main \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive \
    && test "$(git rev-list --all | head -1)" = 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e \
    && test "$(git rev-list --all | wc -l)" = "$(git rev-list HEAD | wc -l)"

# Dependency versions current as of the base commit (2021-12-05, requests 2.26.0),
# following requirements-dev.txt (pytest<=6.2.5, pytest-httpbin 1.0.0, Flask<2).
RUN pip install "pip<22" "setuptools<60" "wheel<0.38" \
    && pip install \
        "pytest==6.2.5" "pytest-cov==3.0.0" "coverage==6.2" \
        "pytest-httpbin==1.0.0" "pytest-mock==2.0.0" \
        "httpbin==0.7.0" "Flask==1.1.4" "Werkzeug==1.0.1" "Jinja2==2.11.3" \
        "itsdangerous==1.1.0" "MarkupSafe==1.1.1" "click==7.1.2" \
        "brotlipy==0.7.0" "decorator==5.1.0" "raven==6.10.0" \
        "trustme==0.9.0" "cryptography==36.0.1" "idna==3.3" \
        "urllib3==1.26.7" "certifi==2021.10.8" "charset-normalizer==2.0.9" \
        "PySocks==1.7.1" \
    && pip install --no-build-isolation -e ".[socks]" \
    && test -z "$(git status --porcelain)"

WORKDIR /testbed
