# x-cmd-action/this-repo

> Pure-shell "clone the current repo" — to `~/.x-repo/<host>/<owner>/<repo>`. No Node.js, no SSH, no extra inputs.

[中文文档](./README.cn.md)

## What it is

Minimal version of [`x-cmd-action/checkout`](../checkout). Clones the repo that triggered the workflow into the **x-cmd local cache layout** (`~/.x-repo/<host>/<owner>/<repo>`), sets the default bot identity, and stops. That's it.

No SSH, no `repository:` input (always the trigger repo), no `fetch-additional`, no `filter`/`sparse-checkout`, no `path` (path is fixed). For those, use `x-cmd-action/checkout`.

## Why "this-repo"?

x-cmd caches repos locally at `~/.x-repo/<provider>/<owner>/<repo>` (see [`x repo`](https://x-cmd.com/#repo) for the cross-agent sharing mechanism). This action lands the trigger repo in exactly that location, so subsequent steps (and other tools on the runner) can find it where x-cmd expects.

Layer 1 (basic setup) action: one thing, the smallest possible thing.

## Where the repo lands

**Unlike `x-cmd-action/checkout`, this action does NOT clone into `$GITHUB_WORKSPACE`.** The repo is cloned to `~/.x-repo/github.com/<owner>/<repo>` (the x-cmd local cache). `$GITHUB_WORKSPACE` stays empty.

Consequence: a bare `run:` after this action runs in an empty workspace, **not** in the repo. To run commands against the repo, either:

```yaml
- uses: x-cmd-action/this-repo@v1

- run: make test
  working-directory: ${{ github.workspace }}   # workspace is empty — wrong

- run: make test
  working-directory: ${{ env.REPO_DIR }}      # set via env below
  env:
    REPO_DIR: ~/.x-repo/github.com/${{ github.repository }}
```

Or use x-cmd tools that know the layout (`x repo`, `x gitb backup`, `x eget`, etc.) — they find the repo on their own.

If you want cwd = repo root in subsequent steps, use `x-cmd-action/checkout` (it clones into `$GITHUB_WORKSPACE`). This action is for when you specifically want the x-cmd cache layout.

## Usage

```yaml
- uses: x-cmd-action/this-repo@v1
```

That's it. The trigger repo lands at `~/.x-repo/github.com/<owner>/<repo>` with `github-actions[bot]` as the local identity.

### With submodules

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    submodules: recursive
```

### Shallow fetch (only when you need it)

By default `depth` is `0` (full history) — this action is for landing the repo locally so downstream x-cmd tools can see it, so full history is the expected use case. Override to a shallow fetch only if you know that's what you want:

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    depth: 1
```

### With LFS

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    lfs: true
```

### With a repo-scoped .gitconfig overlay (`gitconfig`)

For repo-specific signing keys, custom identity, hooks, etc. — values in this file override `~/.gitconfig` for this checkout only:

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    gitconfig: .github/repo.gitconfig
```

`.github/repo.gitconfig`:

```ini
[user]
    signingkey = ~/.ssh/repo-signing-key
    email = this-repo-only@example.com

[commit]
    gpgsign = true
```

> **Why no `name` / `email` input?** Identity is configured inside the `gitconfig` file's `[user]` section. Same effect, more flexible (you can also override signing keys, hooks, etc.).
>
> **Naming convention:** the `gitconfig` input means "path to a .gitconfig file, applied as `[include]` at the appropriate scope". On this action it's repo-scoped (writes the repo's `.git/config`); on [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) the same input name is job-global (writes `~/.gitconfig`).

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `ref` | `${{ github.ref_name }}` | branch / tag / SHA |
| `depth` | `0` | commits to fetch; `0` = full history (default — this-repo is for local caching, full history is the expected case) |
| `lfs` | `false` | pull LFS files after checkout |
| `submodules` | `false` | `false` / `true` / `recursive` |
| `github-server-url` | `${{ github.server_url }}` | override for Enterprise |
| `gitconfig` | — | path to a `.gitconfig`; added as `[include]` in the repo's `.git/config` (repo-scoped only) |

That's the full list. If you need anything else (SSH, custom path, sparse-checkout, filter, …), use `x-cmd-action/checkout`.

## License

Apache 2.0 — see [`LICENSE`](LICENSE).

## Related

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) — full `actions/checkout` alternative (Layer 2 / common functions). Has SSH, sparse, filter, etc.
- [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) — global `~/.gitconfig` setup. Use when you want config to apply to every git command in the job.
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) — org profile + roadmap.
- [x-cmd `repo`](https://x-cmd.com/#repo) — the local cache layout (`~/.x-repo/...`) this action lands into.
