# 追加仕様: Reward Select廃止とショップ統合

## 1. 概要

MVPでは、ステージクリア後の `Reward Select` 画面を廃止する。

本作の強化サイクルは、ステージ中にスコアとGoldを稼ぎ、ステージクリア後にショップでGoldを使ってビルドを強化する構造に集約する。

これにより、無料報酬選択とショップ購入の役割重複を避け、ゲームテンポを改善する。

---

## 2. 修正後の基本フロー

### 旧フロー

```text
Stage Play
  ↓
Stage Clear
  ↓
Reward Select
  ↓
Shop
  ↓
Next Stage
```

### 新フロー

```text
Stage Play
  ↓
Stage Clear / Cash Out
  ↓
Shop
  ↓
Next Stage
```

より簡潔には、以下のサイクルとする。

```text
プレイする
  ↓
Goldを得る
  ↓
ショップで買う
  ↓
次へ進む
```

---

## 3. Reward Selectを廃止する理由

### 3.1 ショップと役割が重複するため

Reward Selectで特殊Gemやレリックを選び、その後ショップでも強化を購入すると、強化判断が二段階になる。

```text
無料報酬で選ぶ
  ↓
ショップでまた選ぶ
```

本作では各ステージ後に必ずショップへ行くため、強化判断はショップに集約する。

---

### 3.2 Goldの価値を明確にするため

Reward Selectを廃止すると、ステージクリア報酬は基本的にGoldへ集約される。

```text
良いプレイをする
  ↓
Goldが増える
  ↓
買える選択肢が増える
```

これにより、ステージ中の行動がショップでの購買力に直接つながる。

プレイヤーは以下を意識してプレイする。

```text
残りMovesを節約したい
スコアを超過したい
コインGemを消したい
石Gemを壊してGoldを稼ぎたい
```

---

### 3.3 画面遷移を軽くするため

MVPではテンポを重視する。

```text
Stage Clear
  ↓
Shop
```

という短い遷移にすることで、ゲームサイクルを明確にする。

---

## 4. Stage Clear / Cash Out画面

Reward Selectを廃止するため、Stage Clear画面は `Cash Out` 画面として扱う。

### 4.1 目的

ステージで得た成果をGoldに換算し、ショップへ進む前に内訳を表示する。

### 4.2 表示内容

```text
Stage 5 / 14 Clear

Score: 48,500 / 42,000
Moves Left: 3

Gold Earned: 14
- Clear Bonus: 8
- Moves Bonus: 3
- Over Score Bonus: 2
- Coin Gem Bonus: 1

[Go to Shop]
```

### 4.3 表示項目

| 項目 | 内容 |
|---|---|
| Stage | 現在ステージ数 |
| Score | 最終スコア / 目標スコア |
| Moves Left | 残り移動回数 |
| Gold Earned | 獲得Gold合計 |
| Gold Breakdown | Gold獲得内訳 |
| Next Button | Shopへ進む |

---

## 5. Shop画面の役割

Reward Selectを廃止するため、ショップは本作の主要な強化画面となる。

### 5.1 ショップの役割

| 役割 | 内容 |
|---|---|
| ビルド強化 | 特殊Gem、レリック、コート付きGem、消費アイテムを購入 |
| デッキ調整 | 不要な通常Gemを削除 |
| 方針転換 | リロールで商品を入れ替える |
| 次ステージ準備 | 次ステージ情報を見て買い物を判断 |
| Gold消費 | ステージで稼いだGoldの使用先 |

---

## 6. MVPショップ構成

### 6.1 商品枠

MVPでは、ショップ商品枠は4枠から開始する。

```text
商品枠:
- 特殊Gem x2
- レリック x1
- コート付きGem or 消費アイテム x1
```

必要に応じて、後続で5枠に拡張する。

```text
拡張案:
- 特殊Gem x2
- レリック x1
- コート付きGem x1
- 消費アイテム x1
```

---

### 6.2 常設サービス

ショップには以下の常設サービスを置く。

| サービス | 内容 |
|---|---|
| Remove Gem | 通常Gemを1個削除 |
| Reroll | 商品枠を再抽選 |
| Start Next Stage | 次ステージへ進む |

```text
[Remove Gem: 8G]
[Reroll: 3G]
[Start Next Stage]
```

---

## 7. 商品カテゴリ

### 7.1 デッキ追加型特殊Gem

山札に追加される特殊Gem。

| 商品例 | 効果 |
|---|---|
| 赤・縦ロケット | 赤として扱う。マッチ時に縦1列を消す |
| 青・横ロケット | 青として扱う。マッチ時に横1列を消す |
| 黄・爆弾 | 黄として扱う。マッチ時に周囲を消す |
| 紫・斜めビーム | 紫として扱う。マッチ時に斜め方向を消す |
| 緑・コインGem | 緑として扱う。消えるとGold獲得 |

---

### 7.2 コート付きGem

コートが付与されたGemを商品として販売する。

MVPでは、既存Gemにコートを付与するサービスよりも、コート付きGemを商品として売る方式を優先する。

| 商品例 | 効果 |
|---|---|
| 金コート付き赤Gem | 消えるとGold+1。山札復帰時にコート復活 |
| 発光コート付き青Gem | スコア上昇。山札復帰時にコート復活 |
| 連鎖コート付き緑Gem | 連鎖中に消えると倍率補正 |
| 保護コート付き黄Gem | 発動後、盤面上ではコートが剥がれる |
| 反復コート付き紫Gem | 発動後、山札上へ戻る |

---

### 7.3 レリック

ラン中ずっと有効なルール変更。

| レリック例 | 効果 |
|---|---|
| 大採掘の紋章 | 6個以上を一度に消した時、倍率+0.30 |
| 連鎖歯車 | 連鎖倍率の伸び+0.05 |
| ロケット工房 | 4個以上を消すと一時ロケット発動 |
| 爆弾工房 | 6個以上を消すと一時爆弾発動 |
| 会員証 | ショップ価格-15% |
| 採石免許 | 石Gemを壊すとGold+1 |

---

### 7.4 消費アイテム

ステージ中に任意発火する盤面介入。

| アイテム例 | 効果 |
|---|---|
| ハンマー | 指定1マスを削除 |
| クロス | 指定地点の縦横を削除 |
| ボム | 指定地点の周囲を削除 |
| リカラー | 指定Gemの色を変える |
| シャッフル | 盤面を再配置 |
| リフレッシュ | 盤面を再生成 |

---

## 8. Gold獲得仕様

Reward Selectを廃止するため、ステージクリア後の主報酬はGoldとする。

### 8.1 Gold計算

```text
Gold Earned =
  Clear Bonus
  + Moves Left Bonus
  + Over Score Bonus
  + Gem / Coat / Relic Bonus
```

### 8.2 Gold内訳

| 報酬 | 内容 |
|---|---|
| Clear Bonus | ステージクリア固定報酬 |
| Moves Left Bonus | 残り移動回数に応じた報酬 |
| Over Score Bonus | 目標超過スコアに応じた報酬 |
| Coin Gem Bonus | コインGemなどによる報酬 |
| Relic Bonus | レリック効果による報酬 |
| Obstacle Bonus | 石Gem破壊などによる報酬 |

---

## 9. 価格帯

MVPの仮価格は以下とする。

| 商品 | 価格目安 |
|---|---:|
| 消費アイテム | 5〜8G |
| 通常特殊Gem | 8〜14G |
| コート付きGem | 10〜16G |
| レリック | 18〜30G |
| Remove Gem | 初回8G、以降上昇 |
| Reroll | 初回3G、ショップ内で使用ごとに+1G |

簡略化する場合は、以下の価格帯を使う。

| 区分 | 価格 |
|---|---:|
| 安い | 5G |
| 普通 | 10G |
| 高い | 20G |
| 非常に高い | 30G |

---

## 10. Reroll仕様

```text
Reroll Cost: 3G
ショップ内で使うたび +1G
次ショップでリセット
```

例:

```text
1回目: 3G
2回目: 4G
3回目: 5G
```

### 将来拡張

| レリック | 効果 |
|---|---|
| 常連客 | 各ショップ最初のリロール無料 |
| 再入荷 | リロール費用-1 |
| 目利き | リロール後、レリック枠が出やすい |
| 掘り出し物 | リロール後、ランダム商品1つ半額 |

---

## 11. Remove Gem仕様

MVPでは通常Gem削除のみを対象とする。

```text
Remove Gem:
指定色の通常Gemを1個削除する
```

### 価格

```text
1回目: 8G
2回目: 10G
3回目: 12G
以降 +2G
```

### UI例

```text
Remove a Gem

Red x10    [Remove Red]
Blue x10   [Remove Blue]
Green x10  [Remove Green]
Yellow x10 [Remove Yellow]
Purple x10 [Remove Purple]

Cost: 8G
```

---

## 12. 次ステージ情報

Run SetupとReward Selectを廃止するため、ショップ画面には次ステージ情報を表示する。

```text
Next Stage: Stage 4 / 14
Target: 12,000
Moves: 15
Stone Gem: 5%
```

### 表示項目

| 項目 | 内容 |
|---|---|
| Stage | 次ステージ番号 |
| Target | 目標スコア |
| Moves | 移動回数 |
| Obstacle Rate | お邪魔Gem率 |
| Special Rule | ステージ特殊ルールがある場合 |

---

## 13. ショップ画面イメージ

```text
+----------------------------------------------------------------+
| Shop after Stage 3 / 14                    Gold: 24             |
|----------------------------------------------------------------|
| +--------------+ +--------------+ +--------------+ +----------+ |
| | Red Rocket   | | Coin Gem     | | Chain Gear   | | Hammer   | |
| | Special Gem  | | Special Gem  | | Relic        | | Item     | |
| | 10G          | | 8G           | | 22G          | | 6G       | |
| | [Buy]        | | [Buy]        | | [Buy]        | | [Buy]    | |
| +--------------+ +--------------+ +--------------+ +----------+ |
|                                                                |
| Services                                                       |
| [Remove Gem: 8G]    [Reroll: 3G]                               |
|                                                                |
|----------------------------------------------------------------|
| Next Stage: Stage 4 / 14                                       |
| Target: 12,000                                                 |
| Moves: 15                                                      |
| Stone Gem: 5%                                                  |
|                                                                |
|                         [Start Next Stage]                     |
+----------------------------------------------------------------+
```

---

## 14. 修正後のMVP画面一覧

| 画面 | 採用 |
|---|---:|
| Boot / Loading | Yes |
| Title | Yes |
| Run Setup | No |
| Stage Intro | Yes |
| Stage Play | Yes |
| Stage Clear / Cash Out | Yes |
| Reward Select | No |
| Shop | Yes |
| Game Over | Yes |
| Result | Yes |
| Options | Yes |
| Pause | Yes |

---

## 15. 修正後の画面遷移

```text
Boot
  ↓
Title
  ↓
Stage Intro: Stage 1 / 14
  ↓
Stage Play
  ↓
Stage Clear / Cash Out
  ↓
Shop after Stage 1 / 14
  ↓
Stage Intro: Stage 2 / 14
  ↓
...
  ↓
Run Clear / Game Over
  ↓
Result
```

将来的には、Stage IntroもShopに統合し、以下のようにしてもよい。

```text
Shop
  ↓
Start Next Stage
  ↓
Stage Play
```

---

## 16. 未確定ポイント

| 論点 | 現状 |
|---|---|
| 商品枠数 | MVPは4枠。必要なら5枠へ拡張 |
| コートの売り方 | MVPではコート付きGem販売を優先 |
| 消費アイテム枠 | MVPでは1枠相当 |
| レリック枠 | MVPでは1枠 |
| Gold量 | 平均10〜15G程度を仮置き |
| Stage Intro | MVPでは残すが、後でShopに統合可能 |

---

## 17. 実装メモ

### 17.1 削除対象

以下はMVP実装対象から外す。

```text
RewardSelectScreen
RewardCard
RewardChoiceService
```

ただし、将来復活する可能性があるなら、完全削除ではなく未使用扱いでもよい。

---

### 17.2 追加/変更対象

```text
StageClearScreen
  - Gold内訳表示を追加
  - Continue先をShopに変更

ShopScreen
  - 次ステージ情報を表示
  - 商品カテゴリを特殊Gem / レリック / コート付きGem / 消費アイテムへ整理

RunFlowController
  - StageClear → Shop → NextStage に変更
```

---

## 18. まとめ

Reward Selectを廃止し、強化判断をショップへ集約する。

これにより、MVPのゲームサイクルは以下になる。

```text
Stage Play
  ↓
Cash Out
  ↓
Shop
  ↓
Next Stage
```

プレイヤーの意思決定は、以下に集約される。

```text
ステージ中にGoldをどれだけ稼ぐか
ショップで何を買うか
次ステージに向けて何を優先するか
```
