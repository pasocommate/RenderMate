Shader "RenderMate/AudioLink/ALAutoCorrelator"
{
    Properties
    {
        [HDR] _BackgroundColor ("Background Color", Color) = (0.1, 0.1, 0.1, 1)
        [HDR] _WaveformColor ("Waveform Tint", Color) = (1, 1, 1, 1)
        _AmplitudeLow ("Amplitude (Low Freq)", Range(0.001, 0.5)) = 0.05
        _AmplitudeHigh ("Amplitude (High Freq)", Range(0.001, 0.5)) = 0.05
        _FreqRangeMax ("Frequency Range Max", Range(0.01, 1.0)) = 1.0
        _HueShiftSpeed ("Hue Shift Speed (cycles/sec)", Range(-1, 1)) = 0.05
        _SaturationMax ("Saturation Max", Range(0, 1)) = 1.0
        _SaturationMin ("Saturation Min", Range(0, 1)) = 0.0
        _SaturationCurve ("Saturation Curve", Range(0.1, 5.0)) = 1.0

        [KeywordEnum(Cartesian, Polar)] _DrawMode ("Draw Mode", Float) = 0
        _CenterX ("Center X", Range(0, 1)) = 0.5
        _CenterY ("Center Y", Range(0, 1)) = 0.5
        _PolarOffsetX ("Polar Ellipse Width", Range(0, 0.5)) = 0.0
        _PolarOffsetY ("Polar Ellipse Height", Range(0, 0.5)) = 0.0
        _EllipseReactivity ("Ellipse Reactivity", Range(0.1, 3.0)) = 1.0

        [HideInInspector] _MainTex ("MainTex (uGUI compat, unused)", 2D) = "white" {}

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma shader_feature_local __ UNITY_UI_ALPHACLIP
            #pragma shader_feature_local _DRAWMODE_CARTESIAN _DRAWMODE_POLAR

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord0 : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                #ifdef UNITY_UI_CLIP_RECT
                float2 worldPosition : TEXCOORD1;
                #endif
            };

            float4 _BackgroundColor;
            float4 _WaveformColor;
            float _AmplitudeLow;
            float _AmplitudeHigh;
            float _FreqRangeMax;
            float _CenterX;
            float _CenterY;
            float _PolarOffsetX;
            float _PolarOffsetY;
            float _EllipseReactivity;
            float _HueShiftSpeed;
            float _SaturationMax;
            float _SaturationMin;
            float _SaturationCurve;
            float4 _ClipRect;

            // HSV → RGB 変換
            float3 Hsv2Rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            v2f vert(appdata_t v)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(v.vertex);
                OUT.uv = v.texcoord0;
                OUT.color = v.color;
                #ifdef UNITY_UI_CLIP_RECT
                OUT.worldPosition = v.vertex.xy;
                #endif
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                if (!AudioLinkIsAvailable())
                {
                    return fixed4(_BackgroundColor.rgb, _BackgroundColor.a * IN.color.a);
                }

                float2 uv = IN.uv;

                float waveformMask;
                float hue;
                float satPos; // 波形内位置 (0=振幅低位置, 1=振幅高位置)

                float2 center = float2(_CenterX, _CenterY);

                #if defined(_DRAWMODE_POLAR)
                {
                    float2 centered = uv - center;
                    float angle = atan2(abs(centered.y), abs(centered.x));
                    // 角度を [0,1] に正規化した後、最大周波数で制限する
                    float t = angle / (UNITY_PI * 0.5) * _FreqRangeMax;

                    float3 ac = AudioLinkLerp(
                        ALPASS_AUTOCORRELATOR + float2(t * AUDIOLINK_WIDTH, 0));
                    float ampScale = lerp(_AmplitudeLow, _AmplitudeHigh, t);
                    float amplitude = abs(ac.r) * ampScale;

                    float2 dir = float2(cos(angle), sin(angle));
                    float acLow = abs(AudioLinkData(ALPASS_AUTOCORRELATOR).r);
                    float ellipseScale = pow(acLow, _EllipseReactivity);
                    float2 ellipseOffset = float2(_PolarOffsetX, _PolarOffsetY) * ellipseScale;
                    float baseRadius = length(ellipseOffset * dir);
                    float remainingScale = max(1.0 - baseRadius * 2.0, 0.0);
                    float waveRadius = baseRadius + amplitude * remainingScale;

                    float dist = length(centered);
                    float aa = max(fwidth(dist), 1e-4);
                    waveformMask = smoothstep(0.0, aa, waveRadius - dist);

                    // 極座標では実際の角度で色相環を一周
                    float fullAngle = atan2(centered.y, centered.x);
                    hue = fullAngle / (2.0 * UNITY_PI) + 0.5;

                    // 中心から波形外縁にかけて彩度上昇
                    satPos = saturate(dist / max(waveRadius, 1e-4));
                }
                #else
                {
                    // 中心からの距離を [0,1] に正規化した後、最大周波数で制限する
                    float mirroredX = abs(2.0 * (uv.x - center.x)) * _FreqRangeMax;
                    float3 ac = AudioLinkLerp(
                        ALPASS_AUTOCORRELATOR + float2(mirroredX * AUDIOLINK_WIDTH, 0));
                    float ampScale = lerp(_AmplitudeLow, _AmplitudeHigh, mirroredX);
                    float amplitude = abs(ac.r) * ampScale;

                    float distFromCenter = abs(uv.y - center.y);
                    float aa = max(fwidth(distFromCenter), 1e-4);
                    waveformMask = smoothstep(aa, 0.0, distFromCenter - amplitude);

                    // 周波数 (中心からの距離) で色相が緩やかに変化
                    hue = mirroredX;

                    // 振幅低位置 (中心線) から高位置 (波形外縁) で彩度上昇
                    satPos = saturate(distFromCenter / max(amplitude, 1e-4));
                }
                #endif

                // 時間で色相シフト
                hue = frac(hue + _Time.y * _HueShiftSpeed);

                float saturation = lerp(_SaturationMin, _SaturationMax, pow(satPos, _SaturationCurve));
                float3 waveformRGB = Hsv2Rgb(float3(hue, saturation, 1.0)) * _WaveformColor.rgb;
                float3 rgb = lerp(_BackgroundColor.rgb, waveformRGB, waveformMask);
                float alpha = lerp(_BackgroundColor.a, _WaveformColor.a, waveformMask)
                            * IN.color.a;

                #ifdef UNITY_UI_CLIP_RECT
                alpha *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip(alpha - 0.001);
                #endif

                return fixed4(rgb, saturate(alpha));
            }
            ENDCG
        }
    }
}
