#!/usr/bin/env bash
# x-cmd-action/this-repo — pure-shell implementation.
#
# Minimal "clone current repo" action: lands the trigger repo on disk at
# ~/.x-repo/<host>/<owner>/<repo> using the runner's token, applies
# default bot identity, and (optionally) overlays a repo-scoped
# .gitconfig via [include]. That's it — no SSH, no advanced fetch
# options, no filter/sparse.

set -eu

# ───────────────────── inputs ─────────────────────
REPOSITORY="${GITHUB_REPOSITORY:-}"
REF="${INPUT_REF:-}"
TOKEN="${GITHUB_TOKEN:-}"
DEPTH="${INPUT_DEPTH:-0}"
LFS="${INPUT_LFS:-false}"
SUBMODULES="${INPUT_SUBMODULES:-false}"
GITHUB_SERVER_URL="${INPUT_GITHUB_SERVER_URL:-https://github.com}"
GITCONFIG="${INPUT_GITCONFIG:-}"

HOST=$(echo "$GITHUB_SERVER_URL" | sed -E 's|^https?://||; s|/.*$||')
[ -z "$REF" ] && REF="HEAD"

# ───────────────────── safe.directory (container safety) ─────────────────────
git config --global --add safe.directory '*' >/dev/null 2>&1 || true

# ───────────────────── target path: ~/.x-repo/<host>/<owner>/<repo> ─────────────────────
X_REPO_ROOT="${HOME}/.x-repo"
TARGET_DIR="${X_REPO_ROOT}/${HOST}/${REPOSITORY}"

mkdir -p "$TARGET_DIR"

# Build authenticated URL
AUTH_URL="https://x-access-token:${TOKEN}@${HOST}/${REPOSITORY}.git"

# ───────────────────── clone or update ─────────────────────
cd "$TARGET_DIR"

if [ -d ".git" ]; then
    echo "this-repo: existing clone detected — updating"
    git remote set-url origin "$AUTH_URL"
    git fetch --depth="$DEPTH" origin "$REF" 2>/dev/null \
        || git fetch origin "$REF"
else
    git init -q
    git remote add origin "$AUTH_URL"
    if [ "$DEPTH" = "0" ]; then
        git fetch origin "$REF"
    else
        git fetch --depth="$DEPTH" origin "$REF"
    fi
fi

git checkout -f FETCH_HEAD 2>/dev/null || git checkout "$REF"

# ───────────────────── expose repo at $GITHUB_WORKSPACE ─────────────────────
# Real repo lives at ~/.x-repo/<host>/<owner>/<repo> (x-cmd local cache). To
# make subsequent steps run in the repo by default (like actions/checkout),
# surface it at $GITHUB_WORKSPACE:
#   - if the workspace is an empty directory, replace it with a symlink to
#     the repo. cwd becomes the repo root.
#   - if the workspace already has files, leave it alone and create a
#     `.this-repo` symlink inside it (use
#     `working-directory: ${{ github.workspace }}/.this-repo`).
if [ -d "$GITHUB_WORKSPACE" ] && [ -z "$(ls -A "$GITHUB_WORKSPACE" 2>/dev/null)" ]; then
    rmdir "$GITHUB_WORKSPACE"
    ln -s "$TARGET_DIR" "$GITHUB_WORKSPACE"
    echo "this-repo: \$GITHUB_WORKSPACE → $TARGET_DIR (cwd = repo root)"
else
    ln -s "$TARGET_DIR" "$GITHUB_WORKSPACE/.this-repo"
    echo "this-repo: \$GITHUB_WORKSPACE/.this-repo → $TARGET_DIR"
fi

# ───────────────────── submodules ─────────────────────
case "$SUBMODULES" in
    true|recursive)
        git submodule sync --recursive
        if [ "$SUBMODULES" = "recursive" ]; then
            git submodule update --init --recursive --depth "$DEPTH"
        else
            git submodule update --init --depth "$DEPTH"
        fi
        ;;
esac

# ───────────────────── LFS ─────────────────────
if [ "$LFS" = "true" ]; then
    if command -v git-lfs >/dev/null 2>&1; then
        git lfs pull
    else
        echo "WARN: git-lfs not installed, skipping LFS pull" >&2
    fi
fi

# ───────────────────── strip credentials ─────────────────────
git remote set-url origin "${GITHUB_SERVER_URL}/${REPOSITORY}.git"

# ───────────────────── git identity (default bot) ─────────────────────
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# ───────────────────── gitconfig (optional, repo-scoped) ─────────────────────
if [ -n "$GITCONFIG" ]; then
    if [ ! -f "$GITCONFIG" ]; then
        echo "ERROR: gitconfig file not found: $GITCONFIG" >&2
        exit 1
    fi
    INCLUDE_PATH=$(realpath "$GITCONFIG")
    git config --local include.path "$INCLUDE_PATH"
    echo "this-repo: gitconfig include.path=$INCLUDE_PATH (repo-scoped)"
fi

echo "this-repo: cloned to $TARGET_DIR"
