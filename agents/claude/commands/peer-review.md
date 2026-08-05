---
description: チームメンバーの変更をreviewerエージェントでピアレビューし、指摘内容を整理
argument-hint: [レビュー対象] [reviewer名]
---

以下の手順を順番に実行してください。

## ステップ1: 引数の解釈

$ARGUMENTS を以下のルールで解釈してください：
- 第一引数: レビュー対象（省略時は `diff` = 現在のunstaged changes + untracked files）
- 第二引数: reviewer名（省略時は全reviewerを並列実行）

### レビュー対象の指定方法
- 指定なし / `diff`: `git diff` + `git ls-files --others --exclude-standard` で新規ファイルも取得
- `staged`: `git diff --cached`
- `branch` または `ブランチ`: `git diff origin/main...HEAD`
- `PR #123` または `pr 123`: `gh pr diff 123`
- その他: そのまま渡す

### 利用可能なreviewer名
- `reviewer` - Claude自身による詳細レビュー
- `codex-reviewer` - Codex CLIを使ったレビュー

reviewer名が上記のいずれにも一致しない場合は、エラーとしてユーザーに利用可能なreviewer名を案内してください。

## ステップ2: レビュー対象の最新化

2回目以降のレビューの可能性があります。
レビュー対象がPRなら、HEADを対象にレビューするようgit fetchやgit mergeで最新化してください。

## ステップ3: レビュー実行

- reviewer名が指定された場合: そのreviewerのエージェントを起動し、レビュー対象の情報を渡してコードレビューを実行する
- reviewer名が省略された場合: 全reviewerのエージェントを**同時に並列起動**し、レビュー対象の情報を渡してコードレビューを実行する

各reviewerへの指示には次を含めること: 「重要度や確信度で指摘を自己フィルタせず、低確信・低重要度のものも含めてすべて報告する。各指摘には確信度と重要度の見積もりを付ける。重要度の選別は後段で行う」

### 尊重すべき点

README.md, CLAUDE.md, AGENTS.md, docs/ などドキュメントがある場合は、各レビューエージェントに直接読ませるか、レビュー対象情報に含めて依頼します。

## ステップ4: レビュー修正

すべてのレビューが完了したら以下を行う。コードは変更してはならない

- 各Agentsのレビュー結果を統合
- MUST / SHOULD / NITS / NO_NEEDに分類
- レビュー結果をClaude Codeユーザーに開示
    - 各結果には以下を含める
        - 分類
        - どのエージェントが指摘したか
        - 指摘件数 `n / 起動したreviewer数`
        - 対応方針
