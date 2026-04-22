---
name: playwright-mcp
description: Web アプリケーションを実ブラウザで探索的に動作確認し、CDP 経由で UA 上のエラー(コンソール例外、ネットワーク失敗、JS エラー等)を調査するスキル。Playwright MCP サーバー(`@playwright/mcp`)の `browser_*` ツール群を用いる。ユーザーが「ブラウザで動かして確認して」「このページの動作を見て」「コンソールエラーを調べて」「フォーム/ログインを試して」「実際に触って挙動を確認」といった実ブラウザでの探索的確認を求めたとき、あるいは失敗するページ・API 呼び出し・UI バグの原因調査を依頼されたときに必ず使用する。画面に起きていることを目で見るのではなくアクセシビリティスナップショットで構造的に把握する点が本スキルの肝。
---

# Playwright MCP — 探索的動作確認 & UA エラー調査

このスキルは、Web アプリケーションを **実ブラウザで触って挙動を確認する** ため、および **ブラウザ上で起きているエラー(コンソール例外・ネットワーク失敗・JS 実行時エラー)を調べる** ために、Playwright MCP サーバーのツール群を使う手順をまとめたもの。

固定シナリオを機械的に実行する「自動テストの作成」ではなく、**実物を動かしながら挙動を観察して次の一手を決める** 探索的な用途に最適化している。テストコードを書き始めないこと。テストファイル(`@playwright/test`)に落とし込みたい場合はユーザーが明示的に依頼してきたときだけ。

## 動作の前提

Playwright MCP が MCP サーバーとして利用可能である必要がある。Claude Code の `.mcp.json` または `claude mcp add` で次のように接続されていることを想定:

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

ツール名は `mcp__playwright__browser_navigate` のような `mcp__<server>__<tool>` 形式で現れる。サーバー名が `playwright` 以外に設定されている場合はそれに合わせる。

使えるツールが見当たらない場合は、ユーザーに MCP の接続状況を確認してもらう。推測で通常の `Bash` による `playwright` CLI 呼び出しに切り替えない(本スキルは MCP 前提)。

## 中核ループ: snapshot → 観察 → 操作 → 再 snapshot

Playwright MCP は **スクリーンショットではなくアクセシビリティツリー** をスナップショットとして返し、各要素に `ref=e17` のような一時 ID を振る。操作系ツールは human-readable な `element` 説明と `ref` の両方を要求する。だから常に次の順で動く:

1. **開く** — `browser_navigate` で対象 URL へ。
2. **見る** — `browser_snapshot` で現在のページ構造と要素の ref を取得。これが探索の目そのもの。
3. **操作** — 取得した ref を使って `browser_click` / `browser_type` / `browser_fill_form` 等を呼ぶ。
4. **再び見る** — 操作後に `browser_snapshot` を再取得。ref は snapshot ごとに振り直されるので古い ref を使い回さない。
5. **観察対象を広げる** — 必要に応じてコンソール・ネットワーク・JS 評価結果などを取りに行く(後述「UA エラー調査」)。

ref を引用せずにクリックしようとしないこと。過去の snapshot の ref を「覚えていた」という前提で操作すると高確率で失敗する。疑わしい時は snapshot を撮り直す。

## 代表的なツール(Playwright MCP)

以下は頻用するもの。正確なパラメータはツールスキーマが真。ここに挙げてないものも必要なら試してよい。

- `browser_navigate(url)` — URL を開く / 移動する。
- `browser_navigate_back()` / `browser_navigate_forward()` — 履歴移動。
- `browser_snapshot()` — アクセシビリティスナップショット取得。**探索の主役**。
- `browser_click(element, ref, doubleClick?, button?, modifiers?)` — クリック。
- `browser_type(element, ref, text, submit?, slowly?)` — テキスト入力。
- `browser_fill_form(fields[])` — 複数入力を一括。
- `browser_press_key(key)` — Enter / ArrowDown 等のキー送出。
- `browser_hover(element, ref)` — ホバー。
- `browser_select_option(element, ref, values[])` — セレクト。
- `browser_wait_for(text?/textGone?/time?)` — 文字列の出現/消失/指定秒待機。
- `browser_take_screenshot(filename?, element?, ref?, fullPage?)` — 視覚記録が必要な時だけ。操作判断の根拠には使わない(snapshot が正)。
- `browser_console_messages()` — コンソール出力の取得(**UA エラー調査の核**)。
- `browser_network_requests()` — 発生した HTTP リクエスト一覧(失敗応答の特定に使う)。
- `browser_evaluate(function)` / `browser_run_code(code)` — ページコンテキストで JS を実行。DOM 状態の細かい検証や CDP 的な深掘りに使う。
- `browser_tabs(action, index?)` — タブの一覧・作成・切り替え・クローズ。
- `browser_handle_dialog(accept, promptText?)` — alert/confirm/prompt の応答。
- `browser_file_upload(paths[])` — ファイル選択ダイアログに対するアップロード。
- `browser_resize(width, height)` — ビューポート変更(レスポンシブ確認)。
- `browser_close()` — ブラウザを閉じる。

## 探索的動作確認の進め方

「動作確認して」と言われたとき、テスト項目を勝手に無限に広げない。代わりに次の流れで進める:

1. **目的を確認する**(曖昧なら一言だけ聞く) — ログインフローを見るのか、特定のフォームなのか、レスポンシブなのか、回帰確認なのか。
2. **入口を開いて snapshot** — ページ全体の構造をまず把握。
3. **主要導線を 1 本通す** — 典型的なユーザー導線を 1 つ選び、途中で snapshot を挟みながら最後まで通す。
4. **観察されたものを報告する** — 途中で気づいた違和感(壊れたリンク、表示崩れの疑い、遅延、コンソール警告)は最後にまとめて渡す。判断はユーザーに。
5. **深掘りは要求ベース** — 追加の確認はユーザーが選んで指示するまで広げない。

ログインが必要なアプリを対象にする場合、デフォルトで永続プロファイルが使われるためセッションが残ることを意識する。本番環境 / 認証済みセッションで触る前に、ユーザーに `--isolated` 起動や対象スコープの確認を一度だけ取ること。詳しくは `references/profiles-and-auth.md`。

## UA エラー調査の進め方

「コンソールにエラーが出ている」「API がこける」「このページだけ挙動がおかしい」といった相談は、単に開いて終わりではなく次の観点で見る:

1. **ページを開く直後の状態を捕まえる** — `browser_navigate` → 即 `browser_console_messages` と `browser_network_requests`。ロード直後の例外・4xx/5xx を取りこぼさない。
2. **再現させる** — 問題が起きる操作を実際に実行。操作後にもう一度 console / network を取る(差分で見る意識)。
3. **console の深読み** — メッセージ種別(error / warning / info)、source、stack を見る。リソース読み込み失敗(例: mixed content、CORS)は console と network の両方に痕跡が残りやすい。
4. **network の深読み** — 失敗リクエストの URL、status、レスポンス本文(あれば)、リクエストヘッダー。XHR/fetch が飛んでいるのに UI に反映されていないケースは、レスポンス内容と UI 状態の突合が必要。
5. **DOM / JS 状態の確認** — 必要なら `browser_evaluate` で `window` の状態、特定要素の class、data-*、テキストを取得。フレームワーク固有のエラー(Vue の warning、React のエラー境界)もここで確認。
6. **切り分け** — クライアント起因(JS 例外・レンダリング失敗)、通信起因(404/500/タイムアウト)、認可起因(401/403)、環境起因(mixed content / CSP / CORS) のどれに該当するかを明示して報告。

詳しいレシピは `references/error-diagnosis.md`。

## スクリーンショット vs スナップショット

`browser_take_screenshot` は **証跡** や **視覚的な崩れの報告** には有効だが、**要素を特定して操作するための根拠にはしない**。snapshot と違ってスクリーンショットから ref は得られず、LLM がピクセルから正確に状態を推定するのは不安定だから。視覚的な崩れを疑うときだけ撮ってユーザーに渡す。

## やらないこと

- テストコード(`@playwright/test` の spec ファイル)を勝手に生成しない。明示依頼があった時だけ。
- 操作のたびに不要なスクリーンショットを撮らない。snapshot で十分。
- 古い ref を再利用しない。ナビゲーション後・モーダル開閉後・DOM 大きく変わった後は snapshot を撮り直す。
- サイト側の利用規約に反する行為(スクレイピング禁止サイトの大量取得、CAPTCHA 回避、bot 検出の迂回)は行わない。
- 本番 DB を変更しうる操作(実決済・本番データ削除・外部への投稿)はユーザーの明示承認なしにボタンを押さない。dry-run や staging の使用を先に提案する。

## 追加リファレンス

必要になった時だけ開く:

- `references/core-workflow.md` — snapshot/ref ベースの操作パターン、form / multi-tab / dialog などの具体例。
- `references/error-diagnosis.md` — console / network / evaluate を使ったエラー切り分けレシピ集。
- `references/profiles-and-auth.md` — 永続プロファイル・isolated モード・storageState を使った認証済みセッションの扱い方。
- `references/setup.md` — MCP サーバーの起動オプション(`--headless`, `--browser`, `--viewport-size`, `--device`, `--allowed-origins` 等)、接続が動かない時の切り分け。
