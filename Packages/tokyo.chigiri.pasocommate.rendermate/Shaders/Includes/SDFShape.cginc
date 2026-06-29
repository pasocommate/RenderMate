#ifndef RENDERMATE_SDFSHAPE_CGINC
#define RENDERMATE_SDFSHAPE_CGINC

// 2D SDF プリミティブと UIPanel 用コーナー形状ディスパッチ。
// SDF の基本式は Inigo Quilez "2D distance functions" (MIT License) を参考にしている。
// https://iquilezles.org/articles/distfunctions2d/
//
// SdShape / SdShapeGradient は以下を呼び出し元で定義済みであること:
//   float _CornerSize;
//   keywords: _CORNER_SQUARE / _CORNER_ROUND / _CORNER_OCTAGON

// 軸に揃った矩形の SDF。外側は +、内側は -（絶対値が距離）。
float SdBox(float2 p, float2 b)
{
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// 角丸矩形の SDF。半径は短辺を超えないよう clamp。
float SdRoundedBox(float2 p, float2 b, float radius)
{
    float r = clamp(radius, 0.0, max(min(b.x, b.y) - 1e-4, 0.0));
    float2 q = abs(p) - max(b - r, 0.0);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// 軸並行矩形の SDF と、四隅を対称に落とす 45 度回転ハーフプレーンとの積集合。
// どちらも真の距離関数なので max() で正しい凸集合交差の SDF になる。
float SdOctagon45Rect(float2 p, float2 b, float cut)
{
    float c = clamp(cut, 0.0, max(min(b.x, b.y) - 1e-4, 0.0));
    float dBox = SdBox(p, b);
    float dDiag = (abs(p.x) + abs(p.y) - (b.x + b.y - c)) * 0.70710678;
    return max(dBox, dDiag);
}

float SdShape(float2 p, float2 b)
{
    #if defined(_CORNER_ROUND)
    return SdRoundedBox(p, b, _CornerSize);
    #elif defined(_CORNER_OCTAGON)
    return SdOctagon45Rect(p, b, _CornerSize);
    #else
    return SdBox(p, b);
    #endif
}

// SDF の解析的勾配。境界 (d≈0) 付近で支配的な面の法線を返す。
float2 SdShapeGradient(float2 p, float2 b)
{
    float2 ap = abs(p);
    float2 s = sign(p);

    #if defined(_CORNER_ROUND)
    float r = clamp(_CornerSize, 0.0, max(min(b.x, b.y) - 1e-4, 0.0));
    float2 q = ap - max(b - r, 0.0);
    return (q.x > 0 && q.y > 0)
        ? s * normalize(max(q, float2(1e-6, 1e-6)))
        : (q.x > q.y ? float2(s.x, 0) : float2(0, s.y));

    #elif defined(_CORNER_OCTAGON)
    float c = clamp(_CornerSize, 0.0, max(min(b.x, b.y) - 1e-4, 0.0));
    float dDiag = (ap.x + ap.y - (b.x + b.y - c)) * 0.70710678;
    float dBox = max(ap.x - b.x, ap.y - b.y);
    return (dDiag > dBox)
        ? s * 0.70710678
        : ((ap.x - b.x > ap.y - b.y) ? float2(s.x, 0) : float2(0, s.y));

    #else
    return (ap.x - b.x > ap.y - b.y) ? float2(s.x, 0) : float2(0, s.y);
    #endif
}

#endif
