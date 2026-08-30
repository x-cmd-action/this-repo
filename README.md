# x-cmd-action/this-repo

> Pure-shell minimal checkout. Clone the trigger repo into `$GITHUB_WORKSPACE`. No Node.js, no SSH, no extras.

[中文文档](./README.cn.md)

## What it is

The minimum useful checkout. Clones the repo that triggered the workflow into `$GITHUB_WORKSPACE` using the runner's token, sets the default bot identity, and stops.

Same observable ergonomics as `actions/checkout`: subsequent `run:` steps run in the repo by default (cwd = `$GITHUB_WORKSPACE` = repo root). No `cd` needed.

What it **doesn't** have (relative to `x-cmd-action/checkout`):

- no SSH (`ssh-key`, `ssh-known-hosts`, `ssh-strict`, `ssh-user`, `known-hosts-url`)
- no `repository:` input (always the trigger repo)
- no `path:` (always `$GITHUB_WORKSPACE`)
- no `fetch-additional`, `filter`, `sparse-checkout`
- no `clean`, `persist-credentials`, `show-progress`, `set-safe-directory` (defaults are baked in)
- no `allow-unsafe-pr-checkout`

Use `x-cmd-action/checkout` if you need any of those.

## Usage

```yaml
- uses: x-cmd-action/this-repo@v1
```

That's it. The trigger repo lands in `$GITHUB_WORKSPACE` with `github-actions[bot]` as the local identity. Subsequent steps:

```yaml
- uses: x-cmd-action/this-repo@v1

- run: ls
  # shows the repo contents — no cd needed

- run: make test
  # cwd = repo root
```

### With submodules

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    submodules: recursive
```

### Shallow fetch (only when you need it)

`depth` defaults to `0` (full history). Override only when you know you want shallow:

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
| `depth` | `0` | commits to fetch; `0` = full history |
| `lfs` | `false` | pull LFS files after checkout |
| `submodules` | `false` | `false` / `true` / `recursive` |
| `github-server-url` | `${{ github.server_url }}` | override for Enterprise |
| `gitconfig` | — | path to a `.gitconfig`; added as `[include]` in the repo's `.git/config` (repo-scoped only) |

That's the full list. If you need anything else (SSH, custom path, sparse-checkout, filter, …), use `x-cmd-action/checkout`.

## Comparison with `x-cmd-action/checkout`

| Dimension | `this-repo` | `checkout` |
| --- | --- | --- |
| Inputs | 6 | 22 + 3 x-cmd enhancements |
| Token / HTTPS clone | ✅ | ✅ |
| SSH auth | ❌ | ✅ |
| `repository:` / `path:` | trigger repo, fixed path | configurable |
| Sparse / filter | ❌ | ✅ |
| `fetch-additional` | ❌ | ✅ |
| `known-hosts-url` | ❌ | ✅ |
| `persist-credentials` | baked in | configurable |
| Default bot identity | ✅ | ✅ |
| `gitconfig` (repo-scoped) | ✅ | ✅ |
| cwd = repo root | ✅ | ✅ |

**Use `this-repo` when you don't need any of the `checkout`-only inputs.** Use `checkout` when you do.

## License

Apache 2.0 — see [`LICENSE`](LICENSE).

## Related

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) — full checkout with SSH, sparse, filter, etc. Use when `this-repo` is too thin.
- [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) — global `~/.gitconfig` setup. Use when you want config to apply to every git command in the job.
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) — org profile + roadmap.
