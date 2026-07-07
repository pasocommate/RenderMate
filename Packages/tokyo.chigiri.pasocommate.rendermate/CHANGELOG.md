# Changelog

## [4.0.0] - 2026-07-07
- 破壊的変更: `UIPanel` の `_FlipY` プロパティを廃止し、`Use MainTex` 有効時は `_MainTex_ST` の Tiling/Offset で UV を調整するように変更。
- `UIPanel` のカスタム Inspector で MainTex の Tiling/Offset を編集できるようにし、狭い Inspector でも入力欄が潰れにくい表示に改善。

## [3.0.0] - 2026-06-30
- Invisible UI シェーダーを追加。
- シェーダーを `UI/` と `Includes/` サブディレクトリに再編成（破壊的変更）。

## [2.0.0] - 2026-06-16
- `UIPanel` に MainTex サンプリング機能を追加し、Video Gamma を置き換え。

## [1.0.0] - 2026-05-11
- RenderMate の初期リリース。
- uGUI Image 向け多機能 UI シェーダー `UIPanel` を追加。
- AudioLink 対応のデモシーンとサンプルマテリアルを追加。
