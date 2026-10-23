FROM python:3.11-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends git patch \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pallets/flask.git /testbed
WORKDIR /testbed

RUN git checkout --detach 7ee9ceb71e868944a46e1ff00b506772a53a4f1d \
    && git remote remove origin \
    && git for-each-ref --format='%(refname)' refs/heads/ refs/tags/ | xargs -r -n1 git update-ref -d \
    && git checkout -B main \
    && git reflog expire --expire=now --all \
    && git gc --prune=now --aggressive \
    && test "$(git rev-list --all | head -1)" = 7ee9ceb71e868944a46e1ff00b506772a53a4f1d

# Dependency versions current as of the base commit (2023-03-11).
RUN pip install --no-cache-dir "setuptools<68" "wheel" \
    && pip install --no-cache-dir \
        "Werkzeug==2.2.3" "Jinja2==3.1.2" "MarkupSafe==2.1.2" \
        "itsdangerous==2.1.2" "click==8.1.3" \
    && pip install --no-cache-dir -r requirements/tests.txt \
    && pip install --no-cache-dir --no-deps --no-build-isolation -e .

WORKDIR /testbed
