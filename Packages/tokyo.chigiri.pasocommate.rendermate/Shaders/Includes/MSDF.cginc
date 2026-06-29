#ifndef RENDERMATE_MSDF_CGINC
#define RENDERMATE_MSDF_CGINC

// MSDF (Multi-channel Signed Distance Field) 共通ユーティリティ。
// UIPanel.shader / HudProgress.shader 等で #include して使う。

// 3 チャンネルから中央値を取り、真の符号付き距離として利用する。
float RmMsdfMedian3(float a, float b, float c)
{
    return max(min(a, b), min(max(a, b), c));
}

// MSDF テクスチャから被覆率アルファを計算する。
// sample   : MSDF テクスチャの RGBA サンプル (RGB=距離チャンネル)
// uv       : サンプリングに使った UV 座標 (fwidth 計算用)
// texelSize: テクスチャの _TexelSize (.xy = 1/width, 1/height)
// pxRange  : MSDF 生成時の pixel range (通常 4)
float RmMsdfAlpha(float4 sample, float2 uv, float2 texelSize, float pxRange)
{
    float sd = RmMsdfMedian3(sample.r, sample.g, sample.b) - 0.5;
    float2 unitRange = pxRange * texelSize;
    float2 screenTexSize = 1.0 / max(fwidth(uv), float2(1e-6, 1e-6));
    float screenPxRange = max(0.5 * dot(unitRange, screenTexSize), 1.0);
    return saturate(sd * screenPxRange + 0.5);
}

#endif
