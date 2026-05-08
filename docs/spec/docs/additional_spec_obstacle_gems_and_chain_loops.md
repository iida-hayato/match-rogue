# 追加仕様: 山札補充・お邪魔Gem・半無限ループの扱い

## 1. 目的

本仕様は、3マッチ・ローグライクデッキビルダーにおける以下の問題と方針を整理する。

- 盤面サイズと山札サイズが近い場合に、消したGemが即座に戻りやすい問題
- 極端なデッキ圧縮による盤面補充・循環の不自然さ
- お邪魔Gemをステージ特性として導入する方針
- プレイヤーの構築結果として発生する長連鎖・半無限ループの扱い
- 処理上の完全無限ループを防ぐための実装ガード

重要な方針として、本作では「山札からGemが降ってくる」体験を維持する。
完全にループを潰すのではなく、プレイヤーが構築した結果として長連鎖や半ループが発生し、ステージを突破できることはゲーム上の成功体験として許容する。

---

## 2. 基本方針

### 2.1 山札から降ってくる体験を維持する

盤面補充は、原則としてPlayer Deck由来の山札から行う。

```text
Player Deck / Stage Draw Pile
  ↓
Board
  ↓ 消去
Discard
  ↓ 山札切れ
Shuffle
```

プレイヤーが構築したデッキ内容が盤面に反映されることは、本作の中核体験である。

### 2.2 完全な無限ループは防ぐが、半無限ループは許容する

本作では、以下のような挙動は許容する。

- 強化済みGemが高頻度で戻ってくる
- 同じ色や同じ効果が何度も循環する
- 長い連鎖が発生する
- 1手で目標スコアを大きく超える
- 構築が噛み合った結果、半無限ループに近い挙動でクリアする

これはローグライクデッキビルダーとしての成功体験であり、完全には抑制しない。

一方で、以下は防ぐ。

- 1手の解決処理が終わらない
- スコア計算が無限に続く
- 盤面補充と消去が停止不能になる
- ゲームがフリーズする

---

## 3. お邪魔Gem仕様

### 3.1 お邪魔Gemはステージ特性として明示する

各ステージには `obstacle_rate` を設定できる。

例:

```text
Stage 6 / 14
Target Score: 42,000
Moves: 15
Obstacle: Stone Gem 5%
```

プレイヤーには、ステージ開始前またはショップの次ステージ情報として、お邪魔Gemの混入率を明示する。

### 3.2 補充時のお邪魔Gem判定

盤面補充時、補充する各マスごとに `obstacle_rate` を判定する。

- 判定に成功した場合、山札からGemを引かず、お邪魔Gemを生成して落とす
- 判定に失敗した場合、通常通り山札からGemを引く

```text
補充1マスごとに判定:

obstacle_rate 成功
  → お邪魔Gemを生成して落とす
  → 山札は減らない

obstacle_rate 失敗
  → 山札からGemを1つ引いて落とす
  → 山札が1つ減る
```

この仕様により、山札から降ってくる感覚を維持しつつ、一定割合で盤面にノイズを入れられる。

### 3.3 Player Deck由来Gemは直接置換しない

お邪魔Gemは補充時に生成される一時Gemであり、Player Deck由来Gemを直接置換しない。

避けるべき仕様:

```text
山札から引く予定だった強化済みGemが、確率でお邪魔Gemに置き換わる
```

この仕様は、プレイヤーが構築・強化したGemを理不尽に無効化するため採用しない。

採用する仕様:

```text
補充判定でお邪魔Gemが出た場合、山札を引かずにお邪魔Gemを生成する
```

これにより、Player Deckの中身は保持される。

---

## 4. MVPのお邪魔Gem: Stone Gem

### 4.1 Stone Gemの仕様

MVPで導入するお邪魔Gemは `Stone Gem` とする。

```text
Stone Gem
- 色を持たない
- 通常のマッチには参加できない
- スコアは0
- Player Deckには入らない
- ステージ終了時に保持されない
- 周囲のGem消去に巻き込まれると破壊される
```

### 4.2 破壊条件

MVPでは、Stone Gemの周囲8マスでGemが消えた場合、Stone Gemを破壊する。

```text
周囲8マスのいずれかでGemが消える
  ↓
Stone Gemが破壊される
  ↓
空いたマスに通常補充が発生する
```

周囲8マスを対象にする理由:

- プレイヤーが破壊しやすい
- 詰まりすぎを防げる
- Stone Gemが連鎖のきっかけになる
- 妨害でありつつ、盤面を崩す補助にもなる

### 4.3 Stone Gemのゲーム上の意味

Stone Gemは、単なる罰ではなく、以下の二面性を持つ。

```text
短期的には邪魔
長期的には盤面を崩し、連鎖を起こしやすくする
```

そのため、Stone Gemは「無限ループ防止用の強制ペナルティ」ではなく、ステージ特性として扱う。

---

## 5. お邪魔率の推奨値

MVPでは、ステージごとにお邪魔率を調整する。

### 5.1 シンプルな進行案

| ステージ帯 | Stone Gem率 |
|---|---:|
| Stage 1 | 0% |
| Stage 2〜4 | 3% |
| Stage 5〜9 | 5% |
| Stage 10〜13 | 8% |
| Stage 14 | 10% |

### 5.2 ステージ種別で分ける案

| ステージ種別 | Stone Gem率 |
|---|---:|
| 通常 | 5% |
| 金脈 | 0% |
| 荒れた鉱山 | 10% |
| ボス | 12% |

MVPでは、まずシンプルに通常ステージ5%を基準とし、序盤だけ低めにする。

---

## 6. 山札サイズとジャスト問題

### 6.1 問題

盤面サイズと山札サイズが同じ場合、初期配置後に山札が空になる。

例:

```text
Board Cells = 64
Stage Draw Pile = 64

初期配置後:
Board = 64
Draw Pile = 0
Discard = 0
```

この状態で3個消すと、Discardに入った3個だけがすぐシャッフルされ、同じ3個が即座に補充候補になる。

```text
3個消える
  ↓
Discard = 3
Draw Pile = 0
  ↓
Discard 3個をシャッフル
  ↓
同じ3個がすぐ落ちる
```

### 6.2 デザイン上の判断

この挙動は完全には禁止しない。

理由:

- デッキ圧縮や強化の結果、同じGemが高頻度で戻ることは面白さにつながる
- 半ループ状態で高得点を出してクリアすることは、ローグライクデッキビルダーとしての成功体験になる
- Stone Gemの混入やシャッフルにより、完全固定化はある程度崩れる

ただし、処理上の無限ループは防止する。

---

## 7. 長連鎖・半無限ループの扱い

### 7.1 許容する挙動

以下の挙動はゲームデザイン上許容する。

```text
- 長い連鎖
- 同じGemの高頻度再登場
- 1手で目標スコア突破
- 高価値Gemの循環
- 特殊Gemやレリックによる半ループ
```

### 7.2 防止する挙動

以下は防止する。

```text
- 1手の処理が終了しない
- 連鎖解決が無制限に続く
- スコアが無限に増える
- ゲームがフリーズする
```

---

## 8. 処理上の無限ループ防止

### 8.1 MVPの上限値

MVPでは、1手あたりの連鎖・解決処理に上限を設ける。

```text
Max Chain Steps per Move: 50
Max Resolution Steps per Move: 100
```

### 8.2 上限到達時の処理

上限に到達した場合、エラーではなくゲーム演出として扱う。

推奨処理:

```text
Chain Overload
  ↓
その時点までのスコアを確定
  ↓
盤面を再生成またはシャッフル
  ↓
連鎖処理を終了
```

MVPでは以下でよい。

```text
最大連鎖数または最大解決ステップに達したら、
その時点までのスコアを確定し、盤面を再生成して連鎖処理を終了する。
```

---

## 9. 実装メモ

### 9.1 補充処理

```gdscript
func refill_cell(cell: BoardCell, stage_rule: StageRule) -> void:
    if randf() < stage_rule.obstacle_rate:
        cell.gem = GemFactory.create_stone_gem()
    else:
        cell.gem = draw_from_pile()
```

### 9.2 Stone Gem破壊判定

```gdscript
func resolve_stone_breaks(cleared_positions: Array[Vector2i]) -> Array[Vector2i]:
    var stones_to_break: Dictionary = {}

    for pos in cleared_positions:
        for neighbor in board.get_neighbors8(pos):
            var gem = board.get_gem(neighbor)
            if gem != null and gem.kind == GemKind.STONE:
                stones_to_break[neighbor] = true

    return stones_to_break.keys()
```

### 9.3 連鎖上限

```gdscript
const MAX_CHAIN_STEPS := 50
const MAX_RESOLUTION_STEPS := 100

func resolve_move() -> void:
    var chain_count := 0
    var resolution_steps := 0

    while board.has_matches():
        if chain_count >= MAX_CHAIN_STEPS:
            trigger_chain_overload()
            break

        if resolution_steps >= MAX_RESOLUTION_STEPS:
            trigger_chain_overload()
            break

        var cleared := resolve_matches()
        var broken_stones := resolve_stone_breaks(cleared)

        board.remove_gems(cleared)
        board.remove_gems(broken_stones)

        board.apply_gravity()
        board.refill()

        chain_count += 1
        resolution_steps += 1
```

---

## 10. UI仕様

### 10.1 Stage Intro

Stage Introでは、お邪魔Gem率を表示する。

```text
Stage 6 / 14

Target Score: 42,000
Moves: 15
Obstacle: Stone Gem 5%

Stone Gem:
Does not match.
Breaks when nearby gems are cleared.
```

### 10.2 Shopの次ステージ情報

ショップ画面の次ステージ情報にも表示する。

```text
Next Stage: 6 / 14
Target: 42,000
Moves: 15
Obstacle: Stone Gem 5%
```

### 10.3 Chain Overload表示

上限到達時には、エラーではなく演出として表示する。

```text
Chain Overload!
Score secured.
Board refreshed.
```

日本語表示案:

```text
連鎖暴走！
スコアを確定しました。
盤面を再生成します。
```

---

## 11. レリック拡張案

Stone Gemは、後からレリックで利用可能にする。

| レリック | 効果 |
|---|---|
| 採石免許 | Stone Gemを破壊するとGold+1 |
| 砕石機 | Stone Gem破壊時、周囲4マスを消す |
| 地質学者 | Stone Gemを壊すたび、ランダムGem1個を+1 |
| 鉱山王 | Stone Gem率+5%、同時消し数倍率+0.2 |
| 浄化水晶 | Stone Gem率を半減 |
| 崩落誘導 | Stone Gemが壊れた時、その列を追加で落下させる |

---

## 12. 確定方針

MVPでは以下を採用する。

```text
- 盤面補充は山札から行う
- 各ステージに obstacle_rate を持たせる
- 補充時、obstacle_rate に応じて山札を引かずStone Gemを生成する
- Stone GemはPlayer Deckには入らない
- Stone Gemは色を持たず、通常マッチに参加しない
- Stone Gemは周囲8マスのGem消去で破壊される
- Stone Gemは妨害でありつつ、連鎖補助にもなる
- 半無限ループに近い挙動はゲーム上許容する
- 処理上の完全無限ループは、最大連鎖数・最大解決ステップ数で防止する
```
