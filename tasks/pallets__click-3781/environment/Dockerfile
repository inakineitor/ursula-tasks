FROM python:3.12-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git sed patch \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pallets/click.git /testbed
WORKDIR /testbed

RUN git checkout 2103e157683c5e4cadc8ee1838df526a54bde9a4 \
    && git remote remove origin \
    && git checkout -B main \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vx main); do git branch -D "$b"; done \
    && git tag -l | xargs -r git tag -d \
    && git for-each-ref --format='%(refname)' refs/remotes/ | xargs -r -n1 git update-ref -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive

# Pins from uv.lock at the base commit (2026-08-19).
RUN pip install --no-cache-dir \
        "pytest==9.0.2" "pluggy==1.6.0" "iniconfig==2.3.0" "packaging==26.0" \
        "pygments==2.20.0" "typing-extensions==4.15.0" "flit_core>=3.11,<4" \
    && pip install --no-cache-dir --no-deps --no-build-isolation -e .

WORKDIR /testbed
