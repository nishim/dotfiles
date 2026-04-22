# Error Diagnosis — UA 上のエラー調査レシピ

ブラウザ上で「何かおかしい」を切り分けるための具体手順。Playwright MCP は CDP 越しに実ブラウザを動かしているので、開発者ツールで見えるものは概ね取りに行ける。

## 基本セット(最初に必ず撮るもの)

問題調査では、対象ページを開いた直後と、問題再現操作の直後の 2 回、次の 3 点を揃える:

1. `browser_snapshot()` — DOM の構造
2. `browser_console_messages()` — コンソールログ(error / warning / info / log)
3. `browser_network_requests()` — 発生した HTTP リクエスト

これが揃えば、ほとんどの UA 起因バグは「どの層で壊れているか」まで絞れる。

## レシピ 1: 「コンソールにエラーが出る」

```
browser_navigate(url="...")
browser_console_messages()
# -> そのままでは大量なので、error のみに注目。
#    よくあるやつ:
#      * Uncaught TypeError / ReferenceError — JS 実行時エラー
#      * Failed to load resource: net::ERR_*, 4xx, 5xx — リソース取得失敗
#      * CORS / CSP / Mixed Content 警告
#      * React / Vue の警告(key 重複、hydration mismatch など)
```

スタックトレースにファイル名と行番号が載っていれば、ソースマップ次第で原因箇所を直接ユーザーに返せる。minified で読めない場合は、該当 URL を network 側から引いて中身を見る手もある。

## レシピ 2: 「API がこけている / 画面が出ない」

```
browser_navigate(url="...")
# 問題の操作を実行してから:
browser_network_requests()
# status が 4xx/5xx のものを抽出。
# 注目点:
#   - URL, method, status
#   - request headers(特に Authorization, Cookie の有無)
#   - response body(あれば)
#   - CORS / preflight(OPTIONS)の挙動
```

401/403 が多ければ認可系(トークン切れ、Cookie が送られてない、SameSite、CSRF)。
500 なら送信ペイロードを見る。ペイロードだけでは分からない時は、同一リクエストを fetch で再発行して比較:

```
browser_evaluate(function="async () => {
  const r = await fetch('/api/x', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({...}) });
  return { status: r.status, body: await r.text() };
}")
```

## レシピ 3: 「クリックしても何も起きない」

無音で失敗するボタンの定番原因:

- ハンドラ内で JS 例外が投げられている → `browser_console_messages()` に出る
- 要素が実は disabled / pointer-events:none → snapshot に `[disabled]` が出ているか確認。または `browser_evaluate` で `getComputedStyle` を見る
- 別要素が上に被さって clickability を奪っている → `browser_evaluate` で `document.elementFromPoint(x, y)` を見る
- クリックは受けているがフェッチが飛んでいない → network で確認(飛んでないのか、飛んで失敗しているのか)
- フレームワークのイベント委譲が外れている → 該当要素の props/listeners を `browser_evaluate` で調べる

## レシピ 4: 「ローカルではいいけど staging でだけ壊れる」

環境差を切り分ける観点:

- CSP: console に `Refused to ...` 系が出る
- Mixed Content: HTTPS ページ上の HTTP リソース、console で警告
- CORS: `Access-Control-Allow-Origin` ヘッダ差異、preflight(OPTIONS)の挙動
- Cookie ドメイン / SameSite: サードパーティ Cookie が staging で切られていないか
- CDN キャッシュ: `Cache-Control` / `Age` / `X-Cache` をレスポンスヘッダで確認

これらは `browser_network_requests` のレスポンスヘッダにほぼ痕跡が残る。

## レシピ 5: 「表示が崩れている」

レイアウト崩れは snapshot だとテキスト構造しか見えないので、視覚情報が必要。

```
browser_take_screenshot(fullPage=true, filename="broken.png")
# 崩れが特定要素なら:
browser_take_screenshot(element="problematic card", ref="e42", filename="card.png")
# CSS 起因かを JS で測定:
browser_evaluate(function="() => {
  const el = document.querySelector('.card');
  const r = el.getBoundingClientRect();
  const s = getComputedStyle(el);
  return { w: r.width, h: r.height, display: s.display, position: s.position, z: s.zIndex };
}")
```

ビューポート幅との相互作用を疑うなら `browser_resize` で複数幅を試す。

## レシピ 6: 「hydration mismatch / SSR 崩れ」

Next.js や Nuxt で頻出。観察ポイント:

- 最初の snapshot(ロード完了直後)と少し待ってから撮った snapshot で DOM 構造が大きく変わっていないか
- console に "Hydration failed" "Text content does not match" 等の warning
- 再現性を確認: `browser_navigate_back` → 再度 navigate で毎回再現するか、初回だけか

## レシピ 7: 「パフォーマンスが悪い気がする」

正確な計測は Chrome DevTools MCP の方が得意(パフォーマンストレース機能がある)。Playwright MCP でできる範囲:

```
browser_evaluate(function="() => {
  const t = performance.getEntriesByType('navigation')[0];
  return {
    ttfb: t.responseStart - t.requestStart,
    domContentLoaded: t.domContentLoadedEventEnd - t.startTime,
    loadEvent: t.loadEventEnd - t.startTime,
  };
}")
```

リソースごとの所要時間:

```
browser_evaluate(function="() => performance.getEntriesByType('resource')
  .map(e => ({ name: e.name, dur: Math.round(e.duration), size: e.transferSize }))
  .sort((a,b) => b.dur - a.dur).slice(0, 20)")
```

深掘りが必要になったら Chrome DevTools MCP の併用をユーザーに提案してよい。

## 報告のまとめ方

ユーザーに返す時は、拾ったログをそのまま貼らず、次の形で整理する:

- **症状**(再現できた / できない / 条件付き)
- **直接原因の推定**(どの層: JS 例外 / 通信 / 認可 / レンダリング / 環境)
- **根拠**(console の該当行、network の該当リクエスト、DOM の該当要素)
- **未確認の仮説**(時間があれば追加で見たい観点)
- **次に試すと良さそうな一手**

特に console と network は生ログがすぐ肥大化するので、関係のありそうな行だけ抜粋する。
