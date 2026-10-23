FROM python:3.12-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pallets/click.git /testbed
WORKDIR /testbed

RUN git checkout 7944461a80b780d060899c8835acab3c273a04a6 \
    && git remote remove origin \
    && git checkout -B main \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vx main); do git branch -D "$b"; done \
    && git tag -l | xargs -r git tag -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive

RUN pip install --no-cache-dir \
        "pytest==9.0.2" "pluggy==1.6.0" "iniconfig==2.3.0" "packaging==26.0" \
        "pygments==2.20.0" "typing-extensions==4.15.0" "flit_core>=3.11,<4" \
    && pip install --no-cache-dir --no-deps --no-build-isolation -e .

WORKDIR /testbed
