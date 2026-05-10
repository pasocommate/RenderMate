#ifndef RENDERMATE_GRADIENTDISSOLVE_CGINC
#define RENDERMATE_GRADIENTDISSOLVE_CGINC

// グラデーション / ディゾルブの t 値評価。線形・放射状の 2 モード。
//
// 呼び出し元で以下を定義済みであること:
//   float4 _GradientCenter;         (EvaluateGradientRaw)
//   float4 _DissolveCenter;         (EvaluateDissolveRaw)
//   float  _DissolveRadius;         (EvaluateDissolveRaw)
//   keywords: _GRADIENT_RADIAL, _DISSOLVE_LINEAR, _DISSOLVE_RADIAL

// 放射状の t 値を計算する。内側を塗りつぶす領域と楕円のアスペクトを明示的に指定できる。
// centerUV     : 0..1 の UV（0.5 = 矩形中心）。
// innerRadius  : スカラー。この楕円の内側は t=0 にクランプ
//                （= グラデ色1／ディゾルブは完全不透明）。
// outerRadius  : スカラー。この楕円以遠は t=1（= グラデ色2）。
//                innerRadius / outerRadius は楕円の主軸方向の「短辺比」で指定する。
// aspect       : (z, w)。楕円のアスペクト比 z:w。(1, 1) で真円、
//                (2, 1) で横 2:1 の楕円。大きい成分が主軸で、そちらを短辺基準とする。
float EvaluateRadial01(float2 pixelPos, float2 halfSize, float2 centerUV, float innerRadius, float outerRadius, float2 aspect, float refSize)
{
    float2 centerPx = (centerUV - 0.5) * (halfSize * 2.0);
    float2 offsetPx = pixelPos - centerPx;

    float2 safeAspect = max(aspect, float2(1e-5, 1e-5));
    float aspectMax = max(safeAspect.x, safeAspect.y);
    float2 aspectNorm = safeAspect / aspectMax;

    float outer = max(outerRadius, 1e-5);
    float inner = clamp(innerRadius, 0.0, outer);
    float ratio = inner / outer;

    float2 outerPx = max(outer * aspectNorm * refSize, float2(1e-5, 1e-5));
    float tOuter = length(offsetPx / outerPx);

    return saturate((tOuter - ratio) / max(1.0 - ratio, 1e-5));
}

float EvaluateGradientRaw(float2 pixelPos, float2 halfSize, float cachedLinearT, float4 range)
{
    #if defined(_GRADIENT_RADIAL)
    float refMin = max(min(halfSize.x, halfSize.y) * 2.0, 1e-5);
    return EvaluateRadial01(pixelPos, halfSize, _GradientCenter.xy, range.x, range.y, range.zw, refMin);
    #else
    return saturate((cachedLinearT - range.x) / max(range.y - range.x, 1e-5));
    #endif
}

float EvaluateDissolveRaw(float2 pixelPos, float2 halfSize, float cachedLinearT)
{
    #if defined(_DISSOLVE_LINEAR)
    return saturate(cachedLinearT);
    #elif defined(_DISSOLVE_RADIAL)
    float refMax = max(max(halfSize.x, halfSize.y) * 2.0, 1e-5);
    return EvaluateRadial01(pixelPos, halfSize, _DissolveCenter.xy, 0.0, _DissolveRadius, float2(1, 1), refMax);
    #else
    return 1.0;
    #endif
}

#endif
