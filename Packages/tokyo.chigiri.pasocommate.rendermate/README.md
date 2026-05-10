# RenderMate / UIPanel

uGUI の `Image` 向け、SDF ベースの多機能 UI シェーダーです。1 枚のマテリアルで以下をまとめて扱えます。

- 角形状（直角 / 角丸 / 45 度カット八角形）の切替
- 枠線（色・太さ）
- 線状 / 同心円グラデーション（本体色への乗算）
- MSDF モード（`_BaseTex` を MSDF として解釈し、拡大しても輪郭が破綻しない文字・アイコンを描画）
- 2 色ブリンク（周期・波形シャープネス可変）
- 線状 / 同心円ディゾルブ（エッジ色付き）
- HDR カラー、CanvasGroup / Image.color との連動

VRChat ワールド（PC / Quest）でそのまま使えるよう、カスタム C# / UdonSharp / BaseMeshEffect を一切使わず、allowlist 収録済みの `UnityEngine.UI.PositionAsUV1` のみで RectTransform 変更に追従します。

---

## クイックスタート

1. **Canvas の設定**
   対象 Canvas を選択 → Inspector の `Additional Shader Channels` で **TexCoord1** にチェック。
   （World Space Canvas は既定で OFF なので特に忘れがち）

2. **Image に Position As UV 1 を追加**
   対象 Image GameObject で `Add Component → UI → Effects → Position As UV 1`。
   **必須です。** これを付けないと角丸や形状が崩れた見た目になります。

3. **マテリアルを割り当て**
   `Packages/tokyo.chigiri.pasocommate.rendermate/Materials/UIPanel.mat` を **複製してから** Image の Material に指定してください（テンプレートを直接編集しないこと）。

4. **Image Type を Simple に**
   `Sliced / Tiled / Filled` は UV 分布が崩れるため非対応です。

5. **Pivot を (0.5, 0.5) に**
   中心基準 SDF を前提に実装されているため、これ以外の pivot では形状が破綻します。

これでマテリアル Inspector の各項目がそのまま反映されるようになります。

---

## レシピ（よくある使い方）

### 角丸ボタン
- Corner Shape = `ROUND`
- Corner Size = 12〜24 px 程度
- Border Width = 2 px、Border Color = お好み（0 で枠線 OFF）
- Gradient = `NONE`

### 斜めカット（八角形）パネル
- Corner Shape = `OCTAGON`
- Corner Size = カット量（px）
- 幅・高さより大きい値を入れるとシェーダー側で自動的に最大値にクランプされます

### MSDF テキスト / アイコンを表示する
- `_BaseTex` に msdfgen で生成した MSDF テクスチャを割り当て
- `Interpret Base as MSDF` = ON、`_Color` で色を設定（MSDF モードではテクスチャ RGB は距離情報として扱われ、色は Color と頂点カラーのみで決まる）
- `MSDF Pixel Range` = 生成時に指定した pxRange（既定は 4）と揃える
- MSDF テクスチャの Filter Mode は `Bilinear`、`sRGB (Color Texture)` は **OFF**、Compression は `None` か `Uncompressed` 推奨
- `_BaseTex_ST` の Tiling/Offset でサイズ・位置を調整

### ブリンク（2 色点滅）
- Blink を ON、`_Color` と `_ColorBlink` の 2 色を設定、Blink Period で周期（秒）を指定
- Blink Sharpness で波形を調整: `0` = 純サイン、`1` = 矩形波（ハード on/off）、中間で任意のソフト矩形波
- アニメーションで Sharpness を動的に変えても滑らかに繋がる

### ディゾルブ（徐々に消える演出）
- Dissolve Mode = `LINEAR`（方向指定）か `RADIAL`（中心から）
- Dissolve Threshold を 0 → 1 にアニメさせると消えていく
- Dissolve Softness で境界のなだらかさ、Dissolve Edge Color / Width で燃えるようなエッジ表現

---

## プロパティ一覧

### 基本色
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_BaseTex` | 2D | 本体テクスチャ。UV に沿って通常のテクスチャとしてサンプルされる（UI の Source Image による上書きは受けない）。未指定時は 1×1 white として扱われるので実質 no-op |
| `_BaseTex_ST` | Vector | Tiling (xy) / Offset (zw) |
| `_Color` | HDR Color | 本体色（ブリンク有効時は開始色） |

### 形状
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_CORNER` | KeywordEnum | `SQUARE` / `ROUND` / `OCTAGON` |
| `_CornerSize` | px (0..128) | 角丸半径 または 八角形カット量 |

### 枠線
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_BorderColor` | HDR Color | 枠色 |
| `_BorderWidth` | px (0..32) | 枠太さ。`0` で枠線 OFF（完全に消える） |

### グラデーション
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_GRADIENT` | KeywordEnum | `NONE` / `LINEAR` / `RADIAL` |
| `_GradientColor1` / `_GradientColor2` | HDR Color | 両端の色 |
| `_GradientAngle` | 度 | 線状のみ。0°=上→下、90°=左→右 |
| `_GradientCenter` | UV (0..1) | 同心円の中心（0.5, 0.5 で矩形中央） |
| `_GradientRadius` | Vector | **x**: 内側半径（ここまでは Gradient Color 1 でフィル）。**y**: 外側半径（ここからは Gradient Color 2 でフィル、x → y がグラデ領域）。**z, w**: 楕円のアスペクト比 z:w（(1,1) で真円、(2,1) で横長 2:1 楕円）。半径は主軸（z/w のうち大きい方）に対して短辺基準の比率 |

※ グラデーションは本体色に乗算で合成し、α は変更しません。

### MSDF モード
`_BaseTex` を MSDF テクスチャとして解釈し、SDF アンチエイリアスを適用する。テクスチャ RGB は距離情報として使われるので、表示色は `_Color`（と頂点カラー）で決まる。

| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_UseMSDF` | Toggle | `_BaseTex` を MSDF として解釈する ON/OFF |
| `_MSDFPixelRange` | Float | msdfgen 生成時の pxRange と合わせる |

### ブリンク
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_BlinkOn` | Toggle | ブリンクの ON/OFF |
| `_ColorBlink` | HDR Color | 点滅時の 2 色目（ON で `_Color` ↔ `_ColorBlink` を行き来） |
| `_BlinkPeriod` | 秒 (0.05..10) | 1 周期の長さ |
| `_BlinkSharpness` | 0..1 | 波形。`0` = 純サイン、`1` = 矩形波（ハード on/off）、中間はソフト矩形波。内部的には `pow(|sin|, exp2(-8·sharpness)) · sign(sin)` |

### ディゾルブ
| プロパティ | 型・単位 | 説明 |
|---|---|---|
| `_DISSOLVE` | KeywordEnum | `OFF` / `LINEAR` / `RADIAL` |
| `_DissolveThreshold` | 0..1 | これ未満の領域が消える |
| `_DissolveSoftness` | Float | 境界のぼかし幅（大きいほどなだらか） |
| `_DissolveAngle` | 度 | 線状の方向（グラデと独立） |
| `_DissolveCenter` | UV (0..1) | 同心円の中心 |
| `_DissolveRadius` | 比率 | 矩形の短辺基準での終端半径（アスペクト比に依存せず常に真円） |
| `_DissolveEdgeColor` | HDR Color | 境界上に乗る色 |
| `_DissolveEdgeWidth` | Float | 境界色が乗る幅 |

### UI 互換（通常は触らない）
`_StencilComp` / `_Stencil` / `_StencilOp` / `_StencilWriteMask` / `_StencilReadMask` / `_ColorMask` / `_UseUIAlphaClip`
いずれも Unity 標準 `UI/Default` と同等。Mask コンポーネントとの併用時に UI 側が自動設定します。

---

## 制約事項（設計上の前提）

| 制約 | 理由 |
|---|---|
| Image Type = **Simple** のみ | Sliced / Tiled / Filled は内部的に UV が書き換わり、SDF 計算の前提が崩れる |
| Pivot = **(0.5, 0.5)** 必須 | `PositionAsUV1` で伝わる座標を中心基準で扱うため |
| 非一様スケール非推奨 | SDF の等方性が崩れ、角丸半径や枠太さが縦横で変わる |
| ドロップシャドウ非対応 | 頂点の外側押し出しができないため、今回スコープ外 |
| 背景ぼかし非対応 | GrabPass が Quest で使えない |

---

## トラブルシューティング

- **角丸にならず、長方形が歪む** → `Position As UV 1` が付いていない、または Canvas の `TexCoord1` が OFF
- **大きくすると MSDF がにじむ** → `_MSDFPixelRange` がテクスチャ生成時の pxRange と一致していない、または `sRGB (Color Texture)` が ON・圧縮が有効になっている
- **枠線が `_BorderWidth = 0` でも薄く残る** → ありません。0 で厳密に消える設計（`borderCoverage` が 0 に潰れるため）
- **CanvasGroup でフェードが効かない** → マテリアルを複数 Image で共有していても vertex color 経由で個別に効きます。効かない場合は Canvas の `Additional Shader Channels` 設定を確認
- **Quest で見た目が崩れる** → HDR 強度を過大にしていないか、OpenGL ES のレンダーターゲット精度で飽和していないかを確認

---

## 内部仕様（触る人向け）

- 頂点座標は `PositionAsUV1` により `TEXCOORD1` へピクセル単位で書き込まれ、そこから中心基準 SDF を計算
- v2f の割り当て: `TEXCOORD0` = UV、`TEXCOORD1` = pixelPos、`TEXCOORD2` = halfSize（4 頂点で `abs(uv1)` が同値になる性質を利用）、`TEXCOORD3` = `cachedT`（点滅 t・線形グラデ t・線形ディゾルブ t をまとめて頂点で評価し補間）、`TEXCOORD4` = worldPosition（`UNITY_UI_CLIP_RECT` 有効時のみ）
- `_CORNER_ROUND` / `_CORNER_OCTAGON` では `clip(shapeAlpha)` で形状外ピクセルを早期破棄し、Quest などの TBDR GPU でタイル書き込みを省略
- キーワード方針: モード系は `shader_feature_local`（マテリアル毎に固定）、`UNITY_UI_CLIP_RECT` だけは Mask が実行時に切り替えるため `multi_compile`
- SDF の数式は Inigo Quilez "2D distance functions"（MIT）をベースに自前実装（出典はシェーダー上部コメントに明記）
- MSDF の AA は Chlumsky 標準の `screenPxRange` 方式
- 点滅波形は `0.5 + 0.5 · sign(sin) · pow(|sin|, exp2(-8·sharpness))` の単一式で sin と矩形波を連続につなぐ

シェーダー本体は [`Shaders/UIPanel.shader`](Shaders/UIPanel.shader)。
