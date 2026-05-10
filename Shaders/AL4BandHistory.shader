Shader "RenderMate/AudioLink/AL4BandHistory"
{
    Properties
    {
        [HDR] _BackgroundColor ("Background Color", Color) = (0, 0, 0, 0)
        [HDR] _BassColor ("Bass Color", Color) = (0.75, 0.75, 0.75, 1)
        [HDR] _LowMidColor ("LowMid Color", Color) = (0.5, 0, 0, 0.5)
        [HDR] _HighMidColor ("HighMid Color", Color) = (0, 0, 0.5, 0.5)
        [HDR] _HighColor ("High Color", Color) = (0, 0.5, 0, 0.5)
        _Sensitivity ("Sensitivity", Range(1, 5)) = 1.0

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
            float4 _BassColor;
            float4 _LowMidColor;
            float4 _HighMidColor;
            float4 _HighColor;
            float _Sensitivity;
            float4 _ClipRect;

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

                // 右=最新, 左=過去
                float delay = (1.0 - uv.x) * AUDIOLINK_WIDTH;

                float bass = saturate(AudioLinkLerp(float2(delay, 0)).r * _Sensitivity);
                float lowMid = saturate(AudioLinkLerp(float2(delay, 1)).r * _Sensitivity);
                float highMid = saturate(AudioLinkLerp(float2(delay, 2)).r * _Sensitivity);
                float high = saturate(AudioLinkLerp(float2(delay, 3)).r * _Sensitivity);

                float aa = max(fwidth(uv.y), 1e-4);

                float bassMask = smoothstep(aa, 0.0, uv.y - bass) * smoothstep(0.0, aa, bass);
                float lowMidMask = smoothstep(aa, 0.0, uv.y - lowMid) * smoothstep(0.0, aa, lowMid);
                float highMidMask = smoothstep(aa, 0.0, uv.y - highMid) * smoothstep(0.0, aa, highMid);
                float highMask = smoothstep(aa, 0.0, uv.y - high) * smoothstep(0.0, aa, high);

                float3 rgb = _BackgroundColor.rgb;
                rgb += _BassColor.rgb * bassMask;
                rgb += _LowMidColor.rgb * lowMidMask;
                rgb += _HighMidColor.rgb * highMidMask;
                rgb += _HighColor.rgb * highMask;

                float alpha = _BackgroundColor.a;
                alpha = max(alpha, bassMask * _BassColor.a);
                alpha = max(alpha, lowMidMask * _LowMidColor.a);
                alpha = max(alpha, highMidMask * _HighMidColor.a);
                alpha = max(alpha, highMask * _HighColor.a);
                alpha *= IN.color.a;

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
