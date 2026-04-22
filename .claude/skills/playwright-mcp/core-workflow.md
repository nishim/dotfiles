# Core Workflow — snapshot/ref ベースの操作パターン

SKILL.md 本体の中核ループを、よくあるシーン別にもう少し具体的に示す。基本は常に「開く → snapshot → ref を使って操作 → 再 snapshot」。

## 1. 最小ループ

```
browser_navigate(url="https://example.com")
browser_snapshot()
# snapshot 出力から ref を読む。たとえば:
#   - textbox "Search" [ref=e12]
#   - button "Go" [ref=e13]
browser_type(element="Search textbox", ref="e12", text="playwright")
browser_click(element="Go button", ref="e13")
browser_snapshot()   # 結果ページの構造を再取得
```

操作系ツールは `element`(自然言語の説明)と `ref` の両方を要求する設計。`element` は意図のログ兼安全確認のためのもの。省略しない。

## 2. フォーム入力

複数フィールドなら `browser_fill_form` がまとめられて効率が良い。1 項目ずつは `browser_type` で十分。

```
browser_navigate(url=".../signup")
browser_snapshot()
browser_fill_form(fields=[
  {element: "Email input", ref: "e3", value: "test@example.com"},
  {element: "Password input", ref: "e4", value: "correct horse battery"},
])
browser_click(element="Sign up button", ref="e5")
browser_wait_for(text="Welcome")  # 成功シグナルを待つ
browser_snapshot()
```

チェックボックスやラジオは `browser_click`、セレクトは `browser_select_option` を使う。

## 3. 動的コンテンツ / 非同期ローディング

「スピナーが消えるまで待つ」「結果リストが現れるまで待つ」は `browser_wait_for`。

```
browser_click(element="Load more", ref="e20")
browser_wait_for(textGone="Loading...")    # スピナー消失
browser_wait_for(text="Showing 20 results") # 結果ヘッダーの出現
browser_snapshot()
```

`time` 指定の固定待機は最終手段。テキスト条件を優先する。

## 4. モーダル / ダイアログ

- DOM 内モーダル(HTML のオーバーレイ): 普通に snapshot に現れる。ref でクリック。
- ブラウザダイアログ(`alert` / `confirm` / `prompt`): `browser_handle_dialog(accept=true, promptText=...)` で応答。

## 5. マルチタブ

リンククリックで新タブが開く場合、自動的にタブ増える。`browser_tabs` で状況確認 → 切り替え。

```
browser_click(element="External link", ref="e8")
browser_tabs(action="list")
browser_tabs(action="select", index=1)
browser_snapshot()
```

## 6. ファイルアップロード

ファイル選択ダイアログが開いた状態で `browser_file_upload` を呼ぶ。実在するローカルファイルのパスが必要。

```
browser_click(element="Upload avatar", ref="e11")  # <input type=file> を開くボタン
browser_file_upload(paths=["/tmp/avatar.png"])
browser_snapshot()
```

## 7. iframe

snapshot 内では iframe は `iframe` ノードとして現れ、内側の要素にも ref が振られる。親ページと同じ要領で ref を使えば操作できる。クロスオリジン iframe は制約があり、その旨が snapshot に表示される。

## 8. レスポンシブ確認

```
browser_resize(width=375, height=667)   # iPhone SE 相当
browser_navigate(url="...")
browser_snapshot()
browser_take_screenshot(filename="mobile.png", fullPage=true)
```

MCP サーバー起動時に `--device="iPhone 15"` を指定しておくと user-agent / touch / DPR も含めてまとめてエミュレートできる(`references/setup.md` 参照)。

## 9. JavaScript を実行して状態を取る

snapshot に出ない情報(`window.__STATE__`、計算済み style、data-* 属性など)は `browser_evaluate` で JS を書いて取る。

```
browser_evaluate(function="() => ({
  url: location.href,
  title: document.title,
  theme: document.documentElement.dataset.theme,
  storeVersion: window.__APP__?.version,
})")
```

`browser_run_code` はより自由に Playwright の `page` オブジェクトを触れる高機能版。テスト的に複数ステップの検証をまとめたいときに使う。

## 10. うまくいかない時のチェック

- 操作が「ref が見つからない」で失敗 → `browser_snapshot` を撮り直す。ナビゲーション・モーダル開閉後は必ず。
- 要素は見えているのに押せない → `browser_wait_for` で可視・活性になるまで待つ。非同期で disabled が外れるケース多し。
- クリックしても何も起きないように見える → `browser_console_messages` で JS 例外が出ていないか即確認。無音で失敗するボタンの原因の多くはそこ。
- 「このページの ref、さっきと違う」 → snapshot ごとに振り直される仕様。直近の snapshot の ref のみ有効。
