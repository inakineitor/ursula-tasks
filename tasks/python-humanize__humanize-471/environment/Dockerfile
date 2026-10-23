FROM python:3.13-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git gettext \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/python-humanize/humanize.git /testbed
WORKDIR /testbed

RUN git checkout 785e5dcc0d0308ad0dff3f6cc0faa7085ad0375b \
    && git remote remove origin \
    && git checkout -B main \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vx main); do git branch -D "$b"; done \
    && git tag -l | xargs -r git tag -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive

ENV SETUPTOOLS_SCM_PRETEND_VERSION=4.16.1.dev34

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir "hatchling>=1.27" hatch-vcs \
        freezegun "pytest>=9" pytest-benchmark pytest-codspeed pytest-cov \
    && pip install --no-cache-dir -e ".[tests]"

# Compile the gettext catalogs (.po -> .mo), as the project's CI does before testing.
RUN bash scripts/generate-translation-binaries.sh

WORKDIR /testbed
