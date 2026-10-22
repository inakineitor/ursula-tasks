FROM python:3.9-bookworm

ENV DEBIAN_FRONTEND=noninteractive PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends git patch && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/psf/requests.git /testbed
WORKDIR /testbed
RUN git checkout -q 39d0fdd9096f7dceccbc8f82e1eda7dd64717a8e \
    && git checkout -q -B main \
    && git remote remove origin \
    && git tag -l | xargs -r git tag -d \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -v '^main$'); do git branch -D "$b"; done \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive -q

# Dependency pins contemporary with the base commit (Dec 2021, requests 2.26.0).
RUN pip install "setuptools<60" "wheel<0.38" "pip<22" \
    && pip install \
        "pytest==6.2.5" "pytest-cov==3.0.0" "pytest-httpbin==1.0.0" "pytest-mock==2.0.0" \
        "httpbin==0.7.0" "Flask==1.1.4" "Werkzeug==1.0.1" "Jinja2==2.11.3" \
        "itsdangerous==1.1.0" "MarkupSafe==1.1.1" "trustme==0.9.0" \
        "PySocks==1.7.1" "urllib3==1.26.7" "idna==3.3" "charset-normalizer==2.0.9" \
        "certifi==2021.10.8" "brotlipy==0.7.0" "decorator==5.1.0" "raven==6.10.0" \
        "cryptography==36.0.1" "pyOpenSSL==21.0.0" \
    && pip install --no-build-isolation -e ".[socks]"

RUN git status --porcelain && test -z "$(git status --porcelain)"
