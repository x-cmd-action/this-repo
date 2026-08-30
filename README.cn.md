# x-cmd-action/this-repo

> 纯 shell "checkout 当前 repo" —— 到 `~/.x-repo/<host>/<owner>/<repo>`。无 Node.js、无 SSH、无多余 input。

[English](./README.md)

## 这是什么

[`x-cmd-action/checkout`](../checkout) 的最小版本。把触发 workflow 的 repo clone 到 **x-cmd 本地缓存布局**（`~/.x-repo/<host>/<owner>/<repo>`），设上默认 bot identity，完事。

没有 SSH、没有 `repository:` input（永远用触发 repo）、没有 `fetch-additional`、没有 `filter` / `sparse-checkout`、没有 `path`（路径固定）。需要这些，用 `x-cmd-action/checkout`。

## 为何叫 "this-repo"？

x-cmd 把 repo 本地缓存在 `~/.x-repo/<provider>/<owner>/<repo>`（见 [`x repo`](https://x-cmd.com/#repo) —— 跨 agent 共享机制）。这个 action 把触发 repo 正好落到那个位置，让后续 step（和 runner 上的其它工具）能在 x-cmd 期望的地方找到它。

Layer 1（basic setup）action：一件事，最小化的那一件。

## Repo 落在哪

**跟 `x-cmd-action/checkout` 不一样，这个 action 不 clone 到 `$GITHUB_WORKSPACE`。** Repo 落到 `~/.x-repo/github.com/<owner>/<repo>`（x-cmd 本地缓存）。`$GITHUB_WORKSPACE` 保持空。

后果：this-action 之后裸 `run:` 跑在空 workspace 里，**不是** repo 里。要在 repo 里跑命令：

```yaml
- uses: x-cmd-action/this-repo@v1

- run: make test
  working-directory: ${{ github.workspace }}   # workspace 是空的 —— 错

- run: make test
  working-directory: ${{ env.REPO_DIR }}      # 用 env 设对
  env:
    REPO_DIR: ~/.x-repo/github.com/${{ github.repository }}
```

或者用知道这个布局的 x-cmd 工具（`x repo`、`x gitb backup`、`x eget` 等）—— 它们自己找 repo。

如果想 cwd = repo 根，用 `x-cmd-action/checkout`（它 clone 到 `$GITHUB_WORKSPACE`）。这个 action 是给**就是想要 x-cmd 缓存布局**的人用的。

## 用法

```yaml
- uses: x-cmd-action/this-repo@v1
```

就这样。触发 repo 落到 `~/.x-repo/github.com/<owner>/<repo>`，local identity 是 `github-actions[bot]`。

### 拉子模块

```yaml
- uses: x-cmd-action/this-repo@v1
  with:
    submodules: recursive
```

### 浅克隆（确实需要时才用）

`depth` 默认 `0`（全量历史）—— 这个 action 是把 repo 本地缓存给后续 x-cmd 工具用，全量是默认预期。只有确实需要时才显式覆盖成浅 fetch：

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
| `depth` | `0` | 取多少历史；`0` = 全量（默认 —— this-repo 是为本地缓存用，全量是默认预期）|
| `lfs` | `false` | checkout 后跑 `git lfs pull` |
| `submodules` | `false` | `false` / `true` / `recursive` |
| `github-server-url` | `${{ github.server_url }}` | Enterprise 覆盖 |
| `gitconfig` | — | `.gitconfig` 文件路径；往 repo 的 `.git/config` 加 `[include]`（仅本 repo）|

就这些。需要别的（SSH、自定义路径、sparse-checkout、filter ……），用 `x-cmd-action/checkout`。

## 许可证

Apache 2.0 —— 见 [`LICENSE`](LICENSE)。

## 相关链接

- [`x-cmd-action/checkout`](https://github.com/x-cmd-action/checkout) —— 完整的 `actions/checkout` 替代品（Layer 2 / common functions）。有 SSH、sparse、filter 等。
- [`x-cmd-action/gitconfig`](https://github.com/x-cmd-action/gitconfig) —— 全局 `~/.gitconfig` 设置。需要 config 作用于整个 job 所有命令时用它。
- [x-cmd-action/.github](https://github.com/x-cmd-action/.github) —— org 主页 + 路线图。
- [x-cmd `repo`](https://x-cmd.com/#repo) —— 本 action 落入的本地缓存布局（`~/.x-repo/...`）。
