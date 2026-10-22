# git hooks

global git hooks


## Requirement

下記コマンドが使えるようにしておく

- actionlint
- reviewdog
- bats (テスト実行用)

## リポジトリ側のフック

グローバルフックの前に下記のリポジトリ側フックがあれば実行する

- `.git/hooks/<hook名>`
- husky: `.husky/<hook名>`
- lefthook: `lefthook.yml` などの設定ファイルがあれば `lefthook run <hook名>`
  - `node_modules/.bin/lefthook` を優先し、無ければ PATH 上の `lefthook` を使う
  - 自動同期でグローバルフック側に書き込まれないよう `--no-auto-install` を付けて実行する

### lefthook を使うリポジトリでの注意

このグローバルフックが `lefthook run` を呼ぶため、`lefthook install` は不要。

- `lefthook install` は実行しない
  - lefthook の npm パッケージは postinstall で `lefthook install` を実行するため、npm / yarn で lefthook を入れると install 時にも自動で実行される（pnpm v10 以降はデフォルトで postinstall をブロックする）
  - lefthook v2.1.0 未満は `core.hooksPath`（このリポジトリの `hooks/`）にフックを書き込み、グローバルフックを壊す
  - v2.1.0 以降はエラーで止まるが、案内される `--force` は `hooks/` に書き込み、`--reset-hooks-path` はグローバルの `core.hooksPath` を unset するため、どちらも使わない
- 壊れた場合はこのリポジトリで `git status` で確認し、`git checkout hooks/` で戻す

## テスト

```sh
npm test
```

## 下記を参考にしている

https://github.com/azu/git-hooks
