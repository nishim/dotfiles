# Setup — MCP サーバー起動オプションと接続トラブル

Playwright MCP サーバーの起動オプションはそこそこ多い。探索的用途で把握しておくと便利なものをまとめる。

## 典型的な `.mcp.json`

```jsonc
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Claude Code から追加する場合:

```
claude mcp add playwright npx @playwright/mcp@latest
```

接続されると `mcp__playwright__browser_*` というツール名で使えるようになる。

## 用途別のおすすめ引数

### 探索的に手元で触る(日常)

```
npx @playwright/mcp@latest
```

デフォルト: headed / chrome / 永続プロファイル。画面が見えていた方が安心できる。

### CI 的に動かす / ヘッドレスで試す

```
npx @playwright/mcp@latest --headless --isolated
```

### 特定ブラウザ

```
--browser=chrome     # デフォルト
--browser=firefox
--browser=webkit
--browser=msedge
```

Safari 系の挙動差異を見たいときは `webkit`。

### モバイル / 任意解像度

```
--device="iPhone 15"                 # UA, DPR, touch まで一括
--viewport-size=375,667              # サイズだけ
```

レスポンシブ確認なら `--device` の方が実機に近い。

### 機微な環境を触るとき

```
--isolated                           # クリーン起動
--storage-state=/path/auth.json      # 事前保存セッションの注入
--user-data-dir=/path                # プロファイル位置の明示
--allowed-origins="https://staging.example.com"
--blocked-origins="https://api.production.example.com"
```

### 既存のブラウザにつなぐ(ユーザーの実環境)

```
--extension
```

別途 Playwright MCP Bridge 拡張のインストールが必要。

### JSON 設定ファイル

上記オプションが増えてきたら:

```
npx @playwright/mcp@latest --config ./pw-mcp.json
```

## 接続が動かない時の切り分け

Claude Code 側で `mcp__playwright__browser_navigate` 等のツールが見えない / 呼ぶとエラーになる場合:

1. **サーバーが起動しているか** — `claude mcp list` で `playwright` が `connected` になっているか。
2. **バージョンの相性** — `@playwright/mcp` の新しすぎる版で Claude Code からの呼び出しが壊れる事例がある(例: 0.0.56 / 0.0.61 系で問題報告)。ツール名が見えているのに "No such tool" が出る場合、固定バージョン(例: `@playwright/mcp@0.0.41`)を試すのが早い。
3. **npx のネットワーク** — 初回は `@playwright/mcp` 本体と Playwright ブラウザバイナリのダウンロードが走る。オフライン / プロキシ環境では別途インストールが必要。
4. **ブラウザバイナリ不足** — 必要なら MCP サーバーの `browser_install` ツール、もしくはユーザーに `npx playwright install chromium` を実行してもらう。
5. **サーバー名の不一致** — `.mcp.json` のキーが `playwright` 以外(例: `pw`)になっていれば、ツール名も `mcp__pw__*` になる。合わせる。

Claude 側から npm のインストール状況を調べにいかない(ユーザー環境のため)。確認が要る情報はユーザーに一言聞く。
