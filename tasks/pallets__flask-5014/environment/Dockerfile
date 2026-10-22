FROM python:3.11-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pallets/flask.git /testbed
WORKDIR /testbed

RUN git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d \
    && git remote remove origin \
    && git checkout -B main \
    && for b in $(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -vx main); do git branch -D "$b"; done \
    && git tag -l | xargs -r git tag -d \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive

RUN pip install --no-cache-dir \
        "Werkzeug==2.2.3" "Jinja2==3.1.2" "MarkupSafe==2.1.2" \
        "itsdangerous==2.1.2" "click==8.1.3" "setuptools<70" \
    && pip install --no-cache-dir -r requirements/tests.txt \
    && pip install --no-cache-dir --no-deps --no-build-isolation -e .

WORKDIR /testbed
