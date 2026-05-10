Shader "RenderMate/HUD/Progress"
{
    // 視界に張り付く HUD プログレス表示。Bar / Pie の 2 モード切替。
    // ZTest Always で常に最前面、Blend SrcAlpha OneMinusSrcAlpha で半透明合成。
    Properties
    {
        [KeywordEnum(BAR, PIE)] _MODE("Mode", Float) = 0
        [HDR] _BaseColor("Base Color (HDR)", Color) = (1, 1, 1, 0.9)
        [HDR] _FillColor("Fill Color (HDR)", Color) = (0.4, 0.85, 1.0, 0.9)
        _Progress("Progress (0..1)", Range(0, 1)) = 0.0

        _RingThickness("Ring Thickness (0=fill, 1=thin)", Range(0, 1)) = 0.0

        // Pie 中央に貼る MSDF デカール
        [Toggle(_DECAL_ON)] _DecalOn("Decal (MSDF)", Float) = 0
        _DecalTex("Decal Texture (MSDF)", 2D) = "white" {}
        [HDR] _DecalColor("Decal Color", Color) = (1, 1, 1, 1)
        _DecalMSDFPixelRange("Decal MSDF Pixel Range", Float) = 4
        _DecalScale("Decal Scale", Vector) = (0.5, 0.5, 0, 0)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Overlay"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "DisableBatching"="True"
        }

        ZTest Always
        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local _MODE_BAR _MODE_PIE
            #pragma shader_feature_local __ _DECAL_ON
            #include "UnityCG.cginc"
            #include "MSDF.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            float4 _BaseColor;
            float4 _FillColor;
            float  _Progress;
            float  _RingThickness;

            #if defined(_DECAL_ON)
            sampler2D _DecalTex;
            float4 _DecalTex_TexelSize;
            float4 _DecalColor;
            float  _DecalMSDFPixelRange;
            float4 _DecalScale;
            #endif

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv  = v.uv;
                return o;
            }

            // 1 px 幅のアンチエイリアスステップ。
            float Aastep(float threshold, float x)
            {
                float fw = max(fwidth(x), 1e-5);
                return smoothstep(threshold - fw, threshold + fw, x);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;

            #ifdef _MODE_BAR
                float progressMask = 1.0 - Aastep(_Progress, uv.x);
                fixed4 col = lerp(_BaseColor, _FillColor, progressMask);
                return col;
            #endif

            #ifdef _MODE_PIE
                // 中心 (0.5, 0.5) からの正規化距離。Quad は常に正方形なので補正不要。
                float2 d = uv - 0.5;
                float r = length(d) * 2.0; // 0..1 (1 = 内接円外周)

                // 12 時方向を 0、時計回りに 0..1。
                float angle = atan2(d.x, d.y);
                angle = angle < 0 ? angle + 6.2831853 : angle;
                float t = angle / 6.2831853;

                float outerMask = 1.0 - Aastep(1.0, r);
                float innerMask = (_RingThickness > 1e-4) ? Aastep(1.0 - _RingThickness, r) : 1.0;
                float shapeMask = outerMask * innerMask;
                float progressMask = 1.0 - Aastep(_Progress, t);
                fixed4 col = lerp(_BaseColor, _FillColor, progressMask);
                col.a *= shapeMask;

                #if defined(_DECAL_ON)
                {
                    float2 decalUV = (uv - 0.5) / max(_DecalScale.xy, float2(1e-3, 1e-3)) + 0.5;
                    float2 decalClamp = step(float2(0, 0), decalUV) * step(decalUV, float2(1, 1));
                    float inBounds = decalClamp.x * decalClamp.y;
                    float4 msdfSample = tex2D(_DecalTex, decalUV);
                    float decalAlpha = RmMsdfAlpha(msdfSample, decalUV, _DecalTex_TexelSize.xy, _DecalMSDFPixelRange) * inBounds;
                    fixed3 decalRgb = lerp(_BaseColor.rgb, _FillColor.rgb, progressMask);
                    col.rgb = lerp(col.rgb, decalRgb, decalAlpha * _DecalColor.a);
                    col.a = max(col.a, decalAlpha * _DecalColor.a);
                }
                #endif

                return col;
            #endif

                return fixed4(0, 0, 0, 0);
            }
            ENDCG
        }
    }
}
