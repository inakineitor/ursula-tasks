FROM python:3.9-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG BASE_COMMIT=e6e300e729dd33956e5448d8be9a0b1540b4e53a

RUN git clone https://github.com/pytest-dev/pytest.git /testbed \
    && cd /testbed \
    && git checkout -q -B main ${BASE_COMMIT} \
    && git remote remove origin \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/); do \
         [ "$b" = "main" ] || git branch -D "$b"; \
       done \
    && git tag --contains ${BASE_COMMIT} | xargs -r git tag -d \
    && rm -rf .git/refs/remotes .git/packed-refs.lock \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive --quiet

WORKDIR /testbed

# Dependency pins contemporary with the base commit (June 2020), matching
# SWE-bench's pytest 5.4 environment for the runtime requirements.
RUN pip install \
        "setuptools<70" "setuptools-scm<8" wheel \
        attrs==23.1.0 \
        iniconfig==1.0.0 \
        more-itertools==10.1.0 \
        packaging==23.1 \
        pluggy==0.13.1 \
        py==1.11.0 \
        toml==0.10.1 \
        argcomplete==1.11.1 \
        hypothesis==5.19.0 \
        mock==4.0.2 \
        nose==1.3.7 \
        requests==2.24.0 \
        xmlschema==1.2.2 \
    && pip install --no-build-isolation --no-deps -e . \
    && python -c "import pytest, _pytest; print(pytest.__version__, _pytest.__file__)"
