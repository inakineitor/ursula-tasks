FROM python:3.14-bookworm

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git gettext patch \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/python-humanize/humanize.git /testbed
WORKDIR /testbed

# Keep only the base commit: no remote, later commits, other branches, tags or reflog.
RUN git checkout -q 785e5dcc0d0308ad0dff3f6cc0faa7085ad0375b \
    && git checkout -q -B main \
    && git remote remove origin \
    && git for-each-ref --format='%(refname)' refs/ | grep -vx refs/heads/main | xargs -r -n1 git update-ref -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive -q \
    && test "$(git rev-list --all | wc -l)" = "$(git rev-list HEAD | wc -l)"

# Tags are gone, so hatch-vcs can't derive the version (git describe: 4.16.0-34-g785e5dc).
ENV SETUPTOOLS_SCM_PRETEND_VERSION=4.16.1.dev34

# Versions available on PyPI at the base commit's date (2026-10-06).
RUN printf '%s\n' \
        coverage==7.16.2 editables==0.5 freezegun==1.5.5 hatch-vcs==0.5.0 hatchling==1.32.4 \
        iniconfig==2.3.0 markdown-it-py==4.2.0 mdurl==0.1.2 packaging==26.3 \
        pathspec==1.1.1 pluggy==1.6.0 py-cpuinfo2==10.1.1 pygments==2.21.0 \
        pytest==9.1.1 pytest-benchmark==5.3.0 pytest-codspeed==5.0.3 \
        pytest-cov==7.1.0 python-dateutil==2.9.0.post0 rich==15.0.0 \
        setuptools==84.0.0 setuptools-scm==10.3.4 six==1.17.0 tomlkit==0.15.1 \
        trove-classifiers==2026.9.21.13 vcs-versioning==2.5.0 \
        > /opt/constraints.txt \
    && pip install -c /opt/constraints.txt editables hatchling hatch-vcs \
    && pip install -c /opt/constraints.txt --no-build-isolation -e ".[tests]"

# Compile the gettext catalogs (.po -> .mo), as the project's CI does before testing.
RUN bash scripts/generate-translation-binaries.sh

WORKDIR /testbed
