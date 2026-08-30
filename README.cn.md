# x-cmd-action/this-repo

> 纯 shell 最精简 checkout。把触发 repo 克隆到 `$GITHUB_WORKSPACE`。无 Node.js、无 SSH、无多余 input。

[English](./README.md)

## 这是什么

最精简可用的 checkout。把触发 workflow 的 repo 克隆到 `$GITHUB_WORKSPACE`，用 runner 的 token，设上默认 bot identity，完事。

跟 `actions/checkout` 一样的可观察 ergonomics：后续 `run:` step 默认就在 repo 里（cwd = `$GITHUB_WORKSPACE` = repo 根）。不用 `cd`。

**没有的**（相对 `x-cmd-action/checkout`）：

- 没 SSH（`ssh-key`、`ssh-known-hosts`、`ssh-strict`、`ssh-user`、`known-hosts-url`）
- 没 `repository:` input（永远用触发 repo）
- 没 `path:`（永远是 `$GITHUB_WORKSPACE`）
- 没 `fetch-additional`、`filter`、`sparse-checkout`
- 没 `clean`、`persist-credentials`、`show-progress`、`set-safe-directory`（默认值写死）
- 没 `allow-unsafe-pr-checkout`

需要以上任何一个，用 `x-cmd-action/checkout`。

## 用法

```yaml
- uses: x-cmd-action/this-repo@v1
```

就这样。触发 repo 落到 `$GITHUB_WORKSPACE`，local identity 是 `github-actions[bot]`。后续 step：

```yaml
- uses: x-cmd-action/this-repo@v1

- run: ls
  # 看到 repo 内容 —— 不用 cd

- run: make test
  # cwd = repo 根
```

### 拉子模块

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    submodules: recursive
```

### 浅克隆（确实需要时才用）

`depth` 默认 `0`（全量）。只有确实需要时才显式覆盖：

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    depth: 1
```

### 拉 LFS

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    lfs: true
```

### Repo-scoped .gitconfig overlay（`gitconfig`）

给单个 checkout 配签名 key、自定义 identity、hooks 等 —— 文件里的值在该 repo 内覆盖 `~/.gitconfig`：

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    gitconfig: .github/repo.gitconfig
```

`.github/repo.gitconfig`：

```ini
[user]
    signingkey = ~/.ssh/repo-signing-key
    email = this-repo-only@example.com

[commit]
    gpgsign = true
```

> **为什么没有 `name` / `email` input？** Identity 配在 `gitconfig` 文件的 `[user]` 段里。效果一样，更灵活（还可以覆盖签名 key、hooks 等）。
>
> **命名约定**：`gitconfig` input 含义固定为"指向一个 .gitconfig 文件，作为 `[include]` 写到对应作用域"。在本 action 上是 repo-scoped（写到 repo 的 `.git/config`）；在 [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) 上同名 input 是 job 全局（写到 `~/.gitconfig`）。

## Inputs

| Input | 默认 | 说明 |
| --- | --- | --- |
| `ref` | `${{ github.ref_name }}` | branch / tag / SHA |
| `depth` | `0` | 取多少历史；`0` = 全量 |
| `lfs` | `false` | checkout 后跑 `git lfs pull` |
| `submodules` | `false` | `false` / `true` / `recursive` |
| `github-server-url` | `${{ github.server_url }}` | Enterprise 覆盖 |
| `gitconfig` | — | `.gitconfig` 文件路径；往 repo 的 `.git/config` 加 `[include]`（仅本 repo）|

就这些。需要别的（SSH、自定义路径、sparse-checkout、filter ……），用 `x-cmd-action/checkout`。

## 跟 `x-cmd-action/checkout` 的对比

| 维度 | `this-repo` | `checkout` |
| --- | --- | --- |
| Inputs | 6 | 22 + 3 x-cmd 增强 |
| Token / HTTPS clone | ✅ | ✅ |
| SSH 认证 | ❌ | ✅ |
| `repository:` / `path:` | 触发 repo，路径固定 | 可配 |
| Sparse / filter | ❌ | ✅ |
| `fetch-additional` | ❌ | ✅ |
| `known-hosts-url` | ❌ | ✅ |
| `persist-credentials` | 写死 | 可配 |
| 默认 bot identity | ✅ | ✅ |
| `gitconfig`（repo-scoped）| ✅ | ✅ |
| cwd = repo 根 | ✅ | ✅ |

**不需要 checkout 专属 input 时用 `this-repo`**。需要时用 `checkout`。

## 许可证

Apache 2.0 —— 见 [`LICENSE`](LICENSE)。

## 相关链接

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) —— 完整 checkout，有 SSH、sparse、filter 等。`this-repo` 不够用时用这个。
- [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) —— 全局 `~/.gitconfig` 设置。需要 config 作用于整个 job 所有命令时用它。
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) —— org 主页 + 路线图。
