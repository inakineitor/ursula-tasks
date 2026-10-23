FROM python:3.13-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git gettext patch \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/python-humanize/humanize.git /testbed
WORKDIR /testbed

RUN git checkout 08cf2c3026cfd7c553e397e1d91ea069eb2a4978 \
    && git remote remove origin \
    && git checkout -B main \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vx main); do git branch -D "$b"; done \
    && git tag -l | xargs -r git tag -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive

# Tags are purged, so hatch-vcs can't derive the version (base commit is 4.16.0-13-g08cf2c3).
ENV SETUPTOOLS_SCM_PRETEND_VERSION=4.16.1.dev13

# Resolve dependencies as of the base commit's date (2026-08-29).
RUN pip install --no-cache-dir "uv==0.8.*" \
    && uv pip install --system --no-cache --exclude-newer 2026-08-30T00:00:00Z \
        "hatchling>=1.27" hatch-vcs editables \
        freezegun "pytest>=9" pytest-benchmark pytest-codspeed pytest-cov \
    && uv pip install --system --no-cache --exclude-newer 2026-08-30T00:00:00Z \
        --no-build-isolation -e ".[tests]"

# Compile the gettext catalogs (.po -> .mo), as the project's CI does before testing.
RUN bash scripts/generate-translation-binaries.sh

WORKDIR /testbed
