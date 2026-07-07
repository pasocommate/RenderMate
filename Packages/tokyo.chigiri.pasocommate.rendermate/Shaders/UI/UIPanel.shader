Shader "RenderMate/UI/UIPanel"
{
    Properties
    {
        // ---- ベース ----
        _BaseTex ("Base Texture", 2D) = "white" {}
        [HDR] _Color ("Color", Color) = (1,1,1,1)

        // uGUI が Image.mainTexture を `_MainTex` にアサインしようとするため、
        // 定義が無いと "doesn't have a texture property '_MainTex'" の警告が出る。
        [HideInInspector] _MainTex ("MainTex (uGUI compat)", 2D) = "white" {}


        // ---- コーナー形状: SDF でアンチエイリアス付きに描画 ----
        [KeywordEnum(SQUARE, ROUND, OCTAGON)] _CORNER ("Corner Shape", Float) = 0
        _CornerSize ("Corner Size", Range(0, 128)) = 16

        // ---- 枠線 (Border): SDF の d=0 ライン上に描く ----
        [HDR] _BorderColor ("Border Color", Color) = (1,1,1,1)
        _BorderWidth ("Border Width", Range(0, 32)) = 0
        // 0 = Image.Color を無視、1 = Image.Color を完全に乗算。中間値は線形に混ぜる。
        _BorderVertexColorInfluence ("Border Image.Color Influence", Range(0, 1)) = 0
        _BorderRingCount ("Border Ring Count", Range(1, 16)) = 1
        _BorderGap ("Border Gap", Range(0, 32)) = 0
        _AudioLinkBorderFilter ("AudioLink Border Filter", Range(0, 3)) = 3
        _AudioLinkBorderIntensity ("AudioLink Border Intensity", Range(0, 1)) = 0

        // ---- グラデーション: 線形（角度指定）または放射状 ----
        [KeywordEnum(NONE, LINEAR, RADIAL)] _GRADIENT ("Gradient Mode", Float) = 0
        [HDR] _GradientColor1 ("Gradient Color 1", Color) = (1,1,1,1)
        [HDR] _GradientColor2 ("Gradient Color 2", Color) = (1,1,1,1)
        _GradientAngle ("Gradient Angle", Range(-180, 180)) = 0
        _GradientCenter ("Gradient Center", Vector) = (0.5,0.5,0,0)
        // x:開始位置(LINEAR) or 内側半径(RADIAL) / y:終了位置(LINEAR) or 外側半径(RADIAL) / z,w:楕円のアスペクト比(RADIAL のみ)
        _GradientRange ("Gradient Range", Vector) = (0,0.5,1,1)

        // ---- MainTex: RawImage の _MainTex をサンプリングする ----
        [Toggle(_USE_MAINTEX)] _UseMainTex ("Use MainTex", Float) = 0
        _Gamma ("Gamma", Float) = 2.2

        // ---- MSDF: Base Texture を MSDF として解釈して SDF アンチエイリアスを適用する ----
        // ON のとき _BaseTex は RGB が MSDF 距離チャンネル、アルファは Median3 由来の被覆率に置き換わり、
        // 色は _Color と頂点カラーでのみ決まる（テクスチャの RGB は使わない）。
        [Toggle(_USE_MSDF)] _UseMSDF ("Interpret Base as MSDF", Float) = 0
        _MSDFPixelRange ("MSDF Pixel Range", Float) = 4

        // ---- Matcap: ビュー空間疑似法線でサンプリングして本体/枠線に加算合成 ----
        // World Space / Camera Space Canvas でのみカメラ向きに応じて変化する。
        // Screen Space Overlay はビュー行列が固定なので視点連動しない。
        [Toggle(_MATCAP_ON)] _MatcapOn ("Enable Matcap", Float) = 0
        _BaseMatcapTex ("Base Matcap", 2D) = "black" {}
        [HDR] _BaseMatcapColor ("Base Matcap Color", Color) = (1,1,1,1)
        // 0 = 疑似ドーム無し（法線=(0,0,1)、純粋な視線角度反映で面全体が均一にシフト）。
        // 正で外向き（凸ドーム）、負で内向き（凹お椀）。絶対値が大きいほど傾きが強くなる。
        _BaseMatcapTilt ("Base Matcap Tilt", Range(-4, 4)) = 0.5
        _BaseMatcapVertexColorInfluence ("Base Matcap Image.Color Influence", Range(0, 1)) = 0
        _BorderMatcapTex ("Border Matcap", 2D) = "black" {}
        [HDR] _BorderMatcapColor ("Border Matcap Color", Color) = (1,1,1,1)
        // 0 = 枠線も法線=(0,0,1)、正で外向き、負で内向きに傾く。絶対値が大きいほど横倒しのエッジ反射に近づく。
        _BorderMatcapTilt ("Border Matcap Tilt", Range(-4, 4)) = 2
        _BorderMatcapVertexColorInfluence ("Border Matcap Image.Color Influence", Range(0, 1)) = 0
        // Matcap 疑似法線を揺らすためのノーマルマップ（tileable / 共通）。
        // Base / Border それぞれで適用強度を個別に指定する。
        [Normal] _MatcapNormalTex ("Matcap Normal Map", 2D) = "bump" {}
        _BaseMatcapNormalStrength ("Base Matcap Normal Strength", Range(0, 2)) = 1
        _BorderMatcapNormalStrength ("Border Matcap Normal Strength", Range(0, 2)) = 1

        // ---- ディゾルブ (Dissolve): 閾値付近でアルファを消す & エッジ色をのせる ----
        [KeywordEnum(OFF, LINEAR, RADIAL)] _DISSOLVE ("Dissolve Mode", Float) = 0
        _DissolveThreshold ("Dissolve Threshold", Range(-1,1)) = 0
        _DissolveSoftness ("Dissolve Softness", Range(0, 0.5)) = 0
        _DissolveAngle ("Dissolve Angle", Range(-180, 180)) = 0
        _DissolveCenter ("Dissolve Center", Vector) = (0.5,0.5,0,0)
        _DissolveRadius ("Dissolve Radius", Float) = 0.5
        [HDR] _DissolveEdgeColor ("Dissolve Edge Color", Color) = (1,1,1,0)
        _DissolveEdgeVertexColorInfluence ("Dissolve Edge Image.Color Influence", Range(0, 1)) = 0

        // ---- 背景ぼかし (Background Blur): GrabPass で背景をぼかして描画する ----
        [Toggle(_BLUR_ON)] _BlurOn ("Background Blur", Float) = 0
        _BlurRadius ("Blur Radius", Range(0, 25)) = 10

        // ---- AudioLink: RMS 音量でグラデーション端点をシフトする ----
        _AudioLinkFilterIntensity ("AudioLink Filter Intensity", Range(0, 3)) = 3
        _AudioLinkShiftStart ("AudioLink Shift Start", Range(-1, 1)) = 0
        _AudioLinkShiftEnd ("AudioLink Shift End", Range(-1, 1)) = 0
        [Enum(Filtered VU RMS,0,Bass,1,Mid,2,Treble,3)] _AudioLinkSource ("AudioLink Source", Float) = 0
        _AudioLinkKickEnvelope ("AudioLink Kick Envelope", Range(0, 1)) = 0
        _AudioLinkKickThreshold ("AudioLink Kick Threshold", Range(0, 0.5)) = 0.02
        _AudioLinkKickGain ("AudioLink Kick Gain", Range(1, 64)) = 24
        _AudioLinkKickDecayFrames ("AudioLink Kick Decay Frames", Range(1, 16)) = 10

        // ---- uGUI Mask 対応用 Stencil ステート（Mask コンポーネント側で自動設定される） ----
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

        // uGUI マテリアルの定番ステート。
        // Cull Off: UI は裏面も描画 / ZWrite Off: 奥行きに書き込まない /
        // ZTest は Canvas（Screen Space / World Space）に応じて Unity が差し替える。
        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        GrabPass { "_UIPanel_GrabTex" }

        Pass
        {
            Name "Default"

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            // モード系キーワードはエディタ上でマテリアル毎に設定するもので、実行時に切り替えないため、
            // shader_feature_local にしてプロジェクト内で実際に使われているバリアントだけをビルドする。
            #pragma shader_feature_local _CORNER_SQUARE _CORNER_ROUND _CORNER_OCTAGON
            #pragma shader_feature_local _ _USE_MSDF
            #pragma shader_feature_local __ _USE_MAINTEX
            // RADIAL は EvaluateRadial01 が重いのでバリアント分離。
            // LINEAR は頂点計算済みで軽いため NONE と同一バリアントに統合し _GRADIENT uniform で分岐。
            #pragma shader_feature_local _ _GRADIENT_RADIAL
            #pragma shader_feature_local _DISSOLVE_OFF _DISSOLVE_LINEAR _DISSOLVE_RADIAL
            #pragma shader_feature_local __ _MATCAP_ON
            #pragma shader_feature_local __ _BLUR_ON
            // UNITY_UI_CLIP_RECT は Mask が実行時に切り替えるので multi_compile が必須。
            // UNITY_UI_ALPHACLIP はマテリアルの Toggle で決まるので shader_feature_local で十分。
            // （AlphaClip を使っていないマテリアルで未使用バリアントのコンパイルを回避できる）
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma shader_feature_local __ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            #define RM_TWO_PI 6.283185307179586

            // Quest (GLES3) では GrabPass 非対応のためぼかしを無効化
            #if defined(_BLUR_ON) && !defined(SHADER_API_GLES3)
            #define RM_BLUR_ENABLED 1
            #endif

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord0 : TEXCOORD0;
                // uv1 にはピクセル単位の座標（中心原点）をセットアップ側で書き込む想定。
                // SDF 評価の入力に使い、halfSize = abs(uv1 の頂点値) で矩形半径を得る。
                float2 uv1 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 pixelPos : TEXCOORD1;
                float2 halfSize : TEXCOORD2;
                // x: 点滅 t、y: 線形グラデーションの t（saturate 前）、z: 線形ディゾルブの t（saturate 前）。
                // 線形モードは UV に対して線形なので、頂点で評価して補間させても結果が変わらない。
                float2 cachedT : TEXCOORD3;
                #ifdef UNITY_UI_CLIP_RECT
                float2 worldPosition : TEXCOORD4;
                #endif
                #if defined(RM_BLUR_ENABLED)
                float4 grabPos : TEXCOORD5;
                #endif
            };

            sampler2D _BaseTex;
            float4 _BaseTex_ST;
            float4 _BaseTex_TexelSize;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Gamma;

            float4 _Color;

            float _CornerSize;

            float4 _BorderColor;
            float _BorderWidth;
            float _BorderVertexColorInfluence;
            float _BorderRingCount;
            float _BorderGap;

            float4 _GradientColor1;
            float4 _GradientColor2;
            float _GradientAngle;
            float4 _GradientCenter;
            float4 _GradientRange;
            float _GRADIENT;

            float _MSDFPixelRange;

            sampler2D _BaseMatcapTex;
            float4 _BaseMatcapColor;
            float _BaseMatcapTilt;
            float _BaseMatcapVertexColorInfluence;
            sampler2D _BorderMatcapTex;
            float4 _BorderMatcapColor;
            float _BorderMatcapTilt;
            float _BorderMatcapVertexColorInfluence;
            sampler2D _MatcapNormalTex;
            float4 _MatcapNormalTex_ST;
            float _BaseMatcapNormalStrength;
            float _BorderMatcapNormalStrength;

            float _DissolveThreshold;
            float _DissolveSoftness;
            float _DissolveAngle;
            float4 _DissolveCenter;
            float _DissolveRadius;
            float4 _DissolveEdgeColor;
            float _DissolveEdgeVertexColorInfluence;

            float4 _ClipRect;

            #if defined(RM_BLUR_ENABLED)
            sampler2D _UIPanel_GrabTex;
            float4 _UIPanel_GrabTex_TexelSize;
            float _BlurRadius;
            #endif

            int _AudioLinkFilterIntensity;
            float _AudioLinkShiftStart;
            float _AudioLinkShiftEnd;
            float _AudioLinkSource;
            float _AudioLinkKickEnvelope;
            float _AudioLinkKickThreshold;
            float _AudioLinkKickGain;
            float _AudioLinkKickDecayFrames;
            int _AudioLinkBorderFilter;
            float _AudioLinkBorderIntensity;

            #include "../Includes/MSDF.cginc"
            #include "../Includes/SDFShape.cginc"
            #include "../Includes/Matcap.cginc"
            #include "../Includes/GradientDissolve.cginc"
            #include "../Includes/AudioLinkSampling.cginc"
            #include "../Includes/BlurDisk.cginc"

            v2f vert(appdata_t v)
            {
                v2f OUT;

                OUT.vertex = UnityObjectToClipPos(v.vertex);
                #if defined(RM_BLUR_ENABLED)
                OUT.grabPos = ComputeGrabScreenPos(OUT.vertex);
                #endif
                OUT.uv = v.texcoord0;

                // uv1 にセットアップ側がピクセル座標（数十〜数百）を書き込む。
                // プレビューメッシュ等 uv1 が未設定の場合は uv0 から仮座標を生成する。
                float2 hs = abs(v.uv1);
                float fallback = step(max(hs.x, hs.y), 1.0);
                float fbSize = 256.0;
                OUT.pixelPos = lerp(v.uv1, (v.texcoord0 - 0.5) * fbSize, fallback);
                OUT.halfSize = lerp(hs, float2(fbSize * 0.5, fbSize * 0.5), fallback);
                OUT.color = lerp(v.color, float4(1, 1, 1, 1), fallback);

                #ifdef UNITY_UI_CLIP_RECT
                OUT.worldPosition = v.vertex.xy;
                #endif

                // 線形グラデーション/ディゾルブは UV に対して線形なので、頂点で計算しておけば
                // ラスタライザの線形補間が正しく効く（= フラグメント側で重い sin/cos 不要）。
                float gradLinearT = 0.0;
                #if !defined(_GRADIENT_RADIAL)
                if (_GRADIENT > 0.5)
                {
                    float gradAngleRad = radians(_GradientAngle);
                    float2 gradDir = float2(sin(gradAngleRad), -cos(gradAngleRad));
                    gradLinearT = dot(v.texcoord0 - 0.5, gradDir) + 0.5;
                }
                #endif

                float dissolveLinearT = 0.0;
                #if defined(_DISSOLVE_LINEAR)
                float dissolveAngleRad = radians(_DissolveAngle);
                float2 dissolveDir = float2(cos(dissolveAngleRad), sin(dissolveAngleRad)) * OUT.halfSize;
                float dissolveExtent = max(abs(dissolveDir.x) + abs(dissolveDir.y), 1e-5);
                dissolveLinearT = dot(v.texcoord0 - 0.5, dissolveDir) / dissolveExtent + 0.5;
                #endif

                OUT.cachedT = float2(gradLinearT, dissolveLinearT);

                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float4 currentColor = _Color;
                #if defined(_USE_MAINTEX)
                float2 mainUV = IN.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                float4 baseSample = tex2D(_MainTex, mainUV);
                #ifndef UNITY_COLORSPACE_GAMMA
                baseSample.rgb = pow(baseSample.rgb, _Gamma);
                #endif
                #else
                float2 baseUV = IN.uv * _BaseTex_ST.xy + _BaseTex_ST.zw;
                float4 baseSample = tex2D(_BaseTex, baseUV);
                #endif
                float baseTexAlpha = baseSample.a;
                #if defined(_USE_MSDF) && !defined(_USE_MAINTEX)
                {
                    baseTexAlpha = RmMsdfAlpha(baseSample, baseUV, _BaseTex_TexelSize.xy, _MSDFPixelRange);
                    baseSample.rgb = float3(1, 1, 1);
                }
                #endif

                float2 halfSize = max(IN.halfSize, float2(1e-4, 1e-4));

                // 2) コーナー形状の SDF を評価。d<0 が内側、d>0 が外側。
                float d = SdShape(IN.pixelPos, halfSize);

                // fwidth(d) で 1 ピクセルあたりの距離変化量を取り、外側のみに AA 遷移帯を置く。
                // 内側 (d<0) は完全不透明を保つため、形状境界が侵食されない。
                float aa = max(fwidth(d), 1e-4);
                float shapeAlpha = 1.0 - smoothstep(0.0, aa, d);

                // 非矩形形状では、形状の外側に出るピクセル（角丸／八角形が削り落とす Quad の四隅）を破棄する。
                // これ以降の MSDF サンプリング・ディゾルブ計算・Border 合成をまとめてスキップでき、
                // Quest のような TBDR GPU ではタイルへの書き込みも省略できる。
                // SQUARE では Quad と形状が完全に一致するので cull する対象は存在しない。
                #if defined(_CORNER_ROUND) || defined(_CORNER_OCTAGON)
                clip(shapeAlpha - 0.001);
                #endif

                // 3) パネル本体色 = Base テクスチャ * Color * 頂点カラー（uGUI の Graphic.color）。
                float3 baseRGB = baseSample.rgb * currentColor.rgb * IN.color.rgb;

                // 3.5) 背景ぼかし: すりガラス効果。ぼかした背景の上にパネル色を合成する。
                // ぼかし済み背景が baseRGB に焼き込まれるため、Color.a の役割は
                // 「パネル色と背景の混合比」だけになる。finalAlpha では消費済みとして
                // currentColor.a を 1 に上書きし、二重適用を防ぐ。
                #if defined(RM_BLUR_ENABLED)
                {
                    float3 blurredBg = RmSampleBlurredGrab(_UIPanel_GrabTex, _UIPanel_GrabTex_TexelSize.xy, IN.grabPos);
                    float panelOpacity = currentColor.a * baseTexAlpha;
                    baseRGB = lerp(blurredBg, baseRGB, panelOpacity);
                    currentColor.a = 1.0;
                    baseTexAlpha = 1.0;
                }
                #endif

                // 4) グラデーションを乗算で合成。_GradientColor{1,2} は HDR なので >1 の輝きも扱える。
                //    RADIAL はコンパイル時確定、LINEAR/NONE は _GRADIENT uniform で分岐。
                #if defined(_GRADIENT_RADIAL)
                const float gradActive = 1.0;
                #else
                float gradActive = _GRADIENT;
                #endif
                if (gradActive > 0.5)
                {
                    float4 gradRange = _GradientRange;
                    if ((_AudioLinkShiftStart != 0.0 || _AudioLinkShiftEnd != 0.0) && AudioLinkIsAvailable())
                    {
                        float rms = RmSampleAudioLinkSignal(_AudioLinkFilterIntensity);
                        gradRange.x += rms * _AudioLinkShiftStart;
                        gradRange.y += rms * _AudioLinkShiftEnd;
                    }
                    float gradT = EvaluateGradientRaw(IN.pixelPos, halfSize, IN.cachedT.x, gradRange);
                    float3 gradRGB = lerp(_GradientColor1.rgb, _GradientColor2.rgb, gradT);
                    baseRGB *= gradRGB;
                }

                // 5a) Base Matcap: パネル中心→現在位置の方向をドーム状の疑似法線として
                // ビュー空間に変換し、matcap テクスチャを加算合成する。ベースカラーの上にのみ乗る。
                #if defined(_MATCAP_ON)
                {
                    float2 baseDirObj = IN.pixelPos / halfSize; // 中心=0、端=±1
                    float2 baseMcUV = RmComputeMatcapUV(baseDirObj, _BaseMatcapTilt, IN.uv, _BaseMatcapNormalStrength);
                    // ミップ選択は摂動無しの滑らかな UV 勾配から。ノーマル不連続での過剰ブラーを防ぐ。
                    float2 baseMcUVSmooth = RmComputeMatcapUVBase(baseDirObj, _BaseMatcapTilt);
                    float3 baseMcRGB = tex2Dgrad(_BaseMatcapTex, baseMcUV, ddx(baseMcUVSmooth), ddy(baseMcUVSmooth)).rgb * _BaseMatcapColor.rgb;
                    baseMcRGB *= lerp(float3(1, 1, 1), IN.color.rgb, _BaseMatcapVertexColorInfluence);
                    baseRGB += baseMcRGB * _BaseMatcapColor.a;
                }
                #endif

                // 5b) Border: 形状エッジ (d = 0) を中心に _BorderWidth の幅で描く帯。
                // `borderCoverage` は幅が AA ピクセル幅の約 2 倍を超えるところで 0 -> 1 に上がるので、
                // _BorderWidth = 0 ならアルファも厳密に 0（AA 由来の細線がうっすら残ることが無い）。
                float borderHalfWidth = max(_BorderWidth, 0.0) * 0.5;
                float borderCoverage = saturate(_BorderWidth / max(aa * 2.0, 1e-4));
                int ringCount = max((int)floor(_BorderRingCount + 0.5), 1);
                float absd = abs(d);
                float borderAlpha;
                float baseFillMask = 1.0;
                if (ringCount <= 1)
                {
                    float dBorder = absd - borderHalfWidth;
                    borderAlpha = (1.0 - smoothstep(0.0, aa, dBorder)) * borderCoverage * shapeAlpha;
                }
                else
                {
                    float ringWidth = max(_BorderWidth * 0.5, 0.0);
                    float ringHalfWidth = ringWidth * 0.5;
                    float ringCoverage = saturate(ringWidth / max(aa * 2.0, 1e-4));

                    // 多重リング時は全リングを形状の内側に配置する。
                    // Ring 0 の中心を境界から ringHalfWidth だけ内側へずらし、
                    // さらに単一リング時の見た目に合わせて有効太さを 0.5x にする。
                    float insideDist = max(-d, 0.0);
                    float period = max(ringWidth + _BorderGap, 1e-4);
                    float dPeriodic = fmod(insideDist - ringHalfWidth + period * 0.5, period) - period * 0.5;
                    float dRing = abs(dPeriodic) - ringHalfWidth;
                    float ringAlpha = (1.0 - smoothstep(0.0, aa, dRing)) * ringCoverage;

                    float maxDist = (ringCount - 1) * period + ringWidth;
                    float rangeMask = 1.0 - smoothstep(0.0, aa, insideDist - maxDist);
                    baseFillMask = smoothstep(0.0, aa, insideDist - maxDist);

                    float audioRevealMask = 1.0;
                    float borderAudioIntensity = saturate(_AudioLinkBorderIntensity);
                    if (borderAudioIntensity > 0.0 && AudioLinkIsAvailable())
                    {
                        float borderRms = RmSampleAudioLinkSignal(_AudioLinkBorderFilter);
                        float threshold = (ringCount - 1) * period * (1.0 - borderRms);
                        float revealDist = insideDist - threshold + ringHalfWidth;
                        float revealMask = smoothstep(0.0, aa, revealDist);
                        audioRevealMask = lerp(1.0, revealMask, borderAudioIntensity);
                    }

                    borderAlpha = ringAlpha * rangeMask * audioRevealMask * shapeAlpha;
                }
                float borderBlend = saturate(borderAlpha * _BorderColor.a);

                // 枠線色に Image.Color（頂点カラー）を influence 分だけ乗算で混ぜる。
                // 0 で _BorderColor そのまま、1 で完全に Image.Color で着色される。
                float3 borderColorMul = lerp(float3(1, 1, 1), IN.color.rgb, _BorderVertexColorInfluence);
                float3 borderRGB = _BorderColor.rgb * borderColorMul;
                #if defined(_MATCAP_ON)
                {
                    float2 borderDirObj = SdShapeGradient(IN.pixelPos, halfSize);
                    float2 borderMcUV = RmComputeMatcapUV(borderDirObj, _BorderMatcapTilt, IN.uv, _BorderMatcapNormalStrength);
                    float2 borderMcUVSmooth = RmComputeMatcapUVBase(borderDirObj, _BorderMatcapTilt);
                    float3 borderMcRGB = tex2Dgrad(_BorderMatcapTex, borderMcUV, ddx(borderMcUVSmooth), ddy(borderMcUVSmooth)).rgb * _BorderMatcapColor.rgb;
                    borderMcRGB *= lerp(float3(1, 1, 1), IN.color.rgb, _BorderMatcapVertexColorInfluence);
                    borderRGB += borderMcRGB * _BorderMatcapColor.a;
                }
                #endif
                float3 baseRGBForBlend = lerp(borderRGB, baseRGB, baseFillMask);
                baseRGB = lerp(baseRGBForBlend, borderRGB, borderBlend);

                // 6) ディゾルブ: threshold を境に softness 幅でアルファを落とし、消え際にエッジ色を加える。
                //    threshold が負の場合は dissolveRaw を反転して逆方向から消す。
                float dissolveAlpha = 1.0;
                #if defined(_DISSOLVE_LINEAR) || defined(_DISSOLVE_RADIAL)
                float dissolveRaw = EvaluateDissolveRaw(IN.pixelPos, halfSize, IN.cachedT.y);
                float isNeg = step(_DissolveThreshold, -1e-6);
                dissolveRaw = lerp(dissolveRaw, 1.0 - dissolveRaw, isNeg);
                float absThreshold = abs(_DissolveThreshold);

                float softness = max(_DissolveSoftness, 1e-5);
                float minEdge = absThreshold - softness * 0.5;
                float maxEdge = absThreshold + softness * 0.5;
                dissolveAlpha = smoothstep(minEdge, maxEdge, dissolveRaw);
                // threshold が 0 や 1 の端に近いとき、遷移帯が [0,1] の外にはみ出すのを防ぐ
                float halfSoft = softness * 0.5;
                dissolveAlpha = lerp(1.0, dissolveAlpha, saturate(absThreshold / halfSoft));
                dissolveAlpha *= saturate((1.0 - absThreshold) / halfSoft);

                // dissolveRaw が threshold 付近の帯でのみ edge > 0 になる。
                // softness をエッジカラーの帯幅としても共用する。
                float edge = 1.0 - saturate(abs(dissolveRaw - absThreshold) / softness);
                edge *= saturate(absThreshold / softness);
                edge *= saturate((1.0 - absThreshold) / softness);
                float3 dissolveEdgeRGB = _DissolveEdgeColor.rgb * lerp(float3(1, 1, 1), IN.color.rgb, _DissolveEdgeVertexColorInfluence);
                baseRGB = lerp(baseRGB, dissolveEdgeRGB, edge * _DissolveEdgeColor.a);
                #endif

                // 7) 最終アルファの合成。ボーダーを前面レイヤーとして Porter-Duff over 合成する。
                //    fillAlpha を borderOpacity 分だけ打ち消し、ボーダーのアルファを加算する。
                //    _BorderColor.a = 0 なら本体に穴が開かず、= 1 ならボーダーで完全に置き換わる。
                float borderOpacity = borderAlpha * _BorderColor.a;
                float fillAlpha = shapeAlpha * baseFillMask * currentColor.a * baseTexAlpha * IN.color.a;
                float borderFinalAlpha = borderOpacity * currentColor.a * IN.color.a;
                float finalAlpha = fillAlpha * (1.0 - borderOpacity) + borderFinalAlpha;

                #if defined(_DISSOLVE_LINEAR) || defined(_DISSOLVE_RADIAL)
                finalAlpha *= dissolveAlpha;
                // 消えた側のエッジ帯でもアルファを復活させ、エッジカラーが見えるようにする
                float edgeAlpha = edge * _DissolveEdgeColor.a * shapeAlpha * baseFillMask * currentColor.a * IN.color.a;
                finalAlpha = max(finalAlpha, edgeAlpha);
                #endif

                // uGUI Mask コンポーネント経由で矩形クリッピング。Mask が無ければ no-op。
                #ifdef UNITY_UI_CLIP_RECT
                finalAlpha *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif

                // 不透明 UI 用のアルファカット（Image.maskable 設定などと組み合わせて使う）。
                #ifdef UNITY_UI_ALPHACLIP
                clip(finalAlpha - 0.001);
                #endif

                fixed4 outColor;
                outColor.rgb = baseRGB;
                outColor.a = saturate(finalAlpha);
                return outColor;
            }
            ENDCG
        }
    }

    CustomEditor "RenderMate.Editor.UIPanelShaderGUI"
}
