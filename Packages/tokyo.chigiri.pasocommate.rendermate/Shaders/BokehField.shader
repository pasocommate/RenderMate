Shader "RenderMate/UI/BokehField"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Background)]
        _BgTop ("Background Top", Color) = (0.52, 0.62, 0.84, 1)
        _BgBottom ("Background Bottom", Color) = (0.20, 0.30, 0.60, 1)
        _FogColor ("Fog Color", Color) = (0.68, 0.75, 0.90, 1)

        [Header(Bokeh Colors)]
        _ColorCool ("Cool (Blue)", Color) = (0.55, 0.80, 1.00, 1)
        _ColorWarm ("Warm (Orange)", Color) = (1.00, 0.75, 0.50, 1)
        _ColorPink ("Pink", Color) = (0.88, 0.60, 0.88, 1)

        [Header(Camera)]
        _CamHeight ("Camera Height", Range(0.5, 5.0)) = 2.0
        _CamPitch ("Camera Pitch (deg)", Range(5, 85)) = 30.0
        _FocalDist ("Focal Distance", Range(1, 30)) = 6.0
        _CoCStr ("CoC Strength", Range(0.1, 5.0)) = 1.5
        _FoV ("Field of View", Range(20, 90)) = 50.0

        [Header(Particles)]
        _Density ("Density", Range(0.05, 1.0)) = 0.6
        _ParticleSize ("Particle Size", Range(0.01, 0.3)) = 0.08
        _Softness ("Edge Softness", Range(0.05, 0.95)) = 0.4
        _Brightness ("Brightness", Range(0.3, 5.0)) = 2.2
        _FogDist ("Fog Distance", Range(5, 80)) = 25.0

        [Header(Floating)]
        _FloatHeight ("Float Height", Range(0.0, 2.0)) = 0.5
        _FloatDensity ("Float Density", Range(0.0, 1.0)) = 0.4

        [Header(Animation)]
        _DriftSpeed ("Drift Speed", Range(0, 2)) = 0.5
        _TwinkleSpeed ("Twinkle Speed", Range(0, 5)) = 2.0
        _TwinkleAmt ("Twinkle Amount", Range(0, 1)) = 0.4

        [Header(Post)]
        _Exposure ("Exposure", Range(0.5, 3.0)) = 1.3
        _Saturation ("Saturation", Range(0, 2)) = 1.15
        _Opacity ("Opacity", Range(0, 1)) = 1

        [HideInInspector]_StencilComp("Stencil Comparison", Float) = 8
        [HideInInspector]_Stencil("Stencil ID", Float) = 0
        [HideInInspector]_StencilOp("Stencil Operation", Float) = 0
        [HideInInspector]_StencilWriteMask("Stencil Write Mask", Float) = 255
        [HideInInspector]_StencilReadMask("Stencil Read Mask", Float) = 255
        [HideInInspector]_ColorMask("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
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
            "VRCFallback"="Transparent"
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _BgTop, _BgBottom, _FogColor;
            fixed4 _ColorCool, _ColorWarm, _ColorPink;
            float _CamHeight, _CamPitch, _FocalDist, _CoCStr, _FoV;
            float _Density, _ParticleSize, _Softness, _Brightness;
            float _FogDist;
            float _FloatHeight, _FloatDensity;
            float _DriftSpeed, _TwinkleSpeed, _TwinkleAmt;
            float _Exposure, _Saturation, _Opacity;
            float4 _ClipRect;

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex        : SV_POSITION;
                fixed4 color         : COLOR;
                float2 uv            : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
            };

            // --- ハッシュ ---
            float hash21(float2 p)
            {
                p = frac(p * float2(127.1, 311.7));
                return frac(sin(dot(p, float2(269.5, 183.3))) * 43758.5453);
            }

            float2 hash22(float2 p)
            {
                float2 q = float2(dot(p, float2(127.1, 311.7)),
                                  dot(p, float2(269.5, 183.3)));
                return frac(sin(q) * 43758.5453);
            }

            // --- 地面の起伏（2オクターブ Value Noise）---
            float groundHeight(float2 xz)
            {
                // 低周波のなだらかな丘陵
                float2 p = xz * 0.3;
                float2 ip = floor(p);
                float2 fp = frac(p);
                fp = fp * fp * (3.0 - 2.0 * fp);
                float a = hash21(ip);
                float b = hash21(ip + float2(1, 0));
                float c = hash21(ip + float2(0, 1));
                float d = hash21(ip + float2(1, 1));
                float h = lerp(lerp(a, b, fp.x), lerp(c, d, fp.x), fp.y);

                p = xz * 0.7;
                ip = floor(p); fp = frac(p);
                fp = fp * fp * (3.0 - 2.0 * fp);
                a = hash21(ip + 73.1); b = hash21(ip + float2(1, 0) + 73.1);
                c = hash21(ip + float2(0, 1) + 73.1); d = hash21(ip + float2(1, 1) + 73.1);
                h += lerp(lerp(a, b, fp.x), lerp(c, d, fp.x), fp.y) * 0.4;

                return (h - 0.5) * 0.06;
            }

            // --- UV → カメラレイ ---
            float3 uvToRay(float2 uv, float aspect, float cp, float sp, float halfTanFov)
            {
                float2 ndc = (uv - 0.5) * 2.0;
                float3 dir;
                dir.x = ndc.x * aspect * halfTanFov;
                dir.y = ndc.y * halfTanFov;
                dir.z = 1.0;
                float3 r;
                r.x = dir.x;
                r.y = dir.y * cp - dir.z * sp;
                r.z = dir.y * sp + dir.z * cp;
                return normalize(r);
            }

            // --- ワールド → スクリーンUV（camZ も返す）---
            float2 projectToScreen(float3 wp, float3 camPos,
                                   float cp, float sp,
                                   float halfTanFov, float aspect,
                                   out float camZ)
            {
                float3 rel = wp - camPos;
                float3 cam;
                cam.x = rel.x;
                cam.y = rel.y * cp + rel.z * sp;
                cam.z = -rel.y * sp + rel.z * cp;
                camZ = cam.z;
                if (cam.z <= 0.001) return float2(-99, -99);
                float2 ndc;
                ndc.x = cam.x / (cam.z * aspect * halfTanFov);
                ndc.y = cam.y / (cam.z * halfTanFov);
                return ndc * 0.5 + 0.5;
            }

            // --- 陰面判定（視線の中点で地面サンプル）---
            bool isOccluded(float3 camPos, float3 wp)
            {
                float3 mid = (camPos + wp) * 0.5;
                return mid.y < groundHeight(mid.xz);
            }

            // --- 色の割り当て ---
            float3 pickColor(float2 cid, float seed, float rnd4)
            {
                float cm = hash21(cid + seed + 55.5);
                if (cm < 0.55)
                    return lerp(_ColorCool.rgb, float3(0.85, 0.92, 1.0), rnd4 * 0.4);
                if (cm < 0.78)
                    return lerp(_ColorPink.rgb, float3(0.95, 0.85, 0.95), rnd4 * 0.3);
                return lerp(_ColorWarm.rgb, float3(1.0, 0.9, 0.75), rnd4 * 0.3);
            }

            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.color = v.color * _Color;
                o.worldPosition = v.vertex;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 sprite = tex2D(_MainTex, i.uv) * i.color;
                float2 uv = i.uv;
                float aspect = abs(ddy(uv.y)) / max(abs(ddx(uv.x)), 0.0001);
                float t = _Time.y;

                // カメラ事前計算
                float pitchRad = _CamPitch * 0.01745329;
                float fovRad = _FoV * 0.01745329;
                float cp = cos(pitchRad);
                float sp = sin(pitchRad);
                float halfTanFov = tan(fovRad * 0.5);
                float3 camPos = float3(0, _CamHeight, 0);

                // カメラレイ
                float3 ray = uvToRay(uv, aspect, cp, sp, halfTanFov);

                // --- 背景 ---
                float3 col = lerp(_BgBottom.rgb, _BgTop.rgb, smoothstep(0.0, 1.0, uv.y));
                float upperHaze = smoothstep(0.5, 0.95, uv.y);
                col = lerp(col, _FogColor.rgb, upperHaze * 0.3);

                // --- 地面との交差 ---
                if (ray.y < -0.0001)
                {
                    // y=0 との交差（初回近似）
                    float gDist0 = -_CamHeight / ray.y;
                    float3 gHit0 = camPos + ray * gDist0;

                    // 地面の起伏を考慮した補正（Newton法 1ステップ）
                    float gh0 = groundHeight(gHit0.xz);
                    float gDist = -(_CamHeight - gh0) / ray.y;
                    float3 gHit = camPos + ray * gDist;

                    float2 worldXZ = gHit.xz;
                    float gridBase = 8.0;

                    // ====== 地面パーティクル（2レイヤー）======
                    [loop]
                    for (int layer = 0; layer < 2; layer++)
                    {
                        float lgs = (layer == 0) ? gridBase * 2.0 : gridBase;
                        float lBright = (layer == 0) ? 0.8 : 1.0;
                        float lSeed = layer * 100.0;

                        float2 gUV = worldXZ * lgs;
                        float2 id = floor(gUV);

                        [loop]
                        for (int ny = -2; ny <= 2; ny++)
                        {
                            [loop]
                            for (int nx = -2; nx <= 2; nx++)
                            {
                                float2 off = float2(nx, ny);
                                float2 cid = id + off;
                                float2 rnd = hash22(cid + lSeed);
                                float rnd3 = hash21(cid + lSeed + 77.7);
                                float rnd4 = hash21(cid + lSeed + 133.3);

                                if (rnd3 > _Density) continue;

                                // 球のワールド座標（地面に接する）
                                float2 pXZ = (cid + rnd) / lgs;
                                float pGH = groundHeight(pXZ);
                                float sizeMul = (layer == 0)
                                    ? lerp(0.008, 0.015, rnd4)
                                    : lerp(0.015, 0.035, rnd4);
                                float wR = _ParticleSize * sizeMul;
                                float sizeBright = 0.02 / max(sizeMul, 0.001);
                                float3 pW = float3(pXZ.x, pGH + wR, pXZ.y);

                                // ドリフト
                                float dph = t * _DriftSpeed * 0.3 * (0.8 + rnd3)
                                          + rnd.x * 6.2831;
                                pW.x += sin(dph) * 0.05;
                                pW.z += sin(dph * 0.7 + 1.5) * 0.03;

                                if (isOccluded(camPos, pW)) continue;

                                // スクリーンに投影
                                float camZ;
                                float2 scrP = projectToScreen(
                                    pW, camPos, cp, sp, halfTanFov, aspect, camZ);
                                if (camZ <= 0.01) continue;

                                // 投影半径（UV空間、Y方向基準）
                                float scrR = wR / (camZ * halfTanFov) * 0.5;

                                // CoC
                                float dist = length(camPos - pW);
                                float coc = saturate(
                                    abs(dist - _FocalDist) / _FocalDist * _CoCStr);
                                float cocR = scrR * (1.0 + coc * 5.0);

                                // フォーカス外の粒子をフェードアウト
                                float cocFade = 1.0 - smoothstep(0.5, 1.0, coc);
                                if (cocFade < 0.001) continue;

                                // スクリーン空間で距離判定（アスペクト補正）
                                float2 delta = (uv - scrP) * float2(aspect, 1.0);
                                float dd = length(delta);
                                float nd = dd / max(cocR, 0.0001);
                                if (nd > 1.15) continue;

                                // 球体/ボケブレンド
                                float sZ = sqrt(max(0.0, 1.0 - nd * nd));
                                float sProf = (sZ * 0.7 + 0.3) * step(nd, 1.0);
                                float soft = _Softness + coc * 0.3;
                                float dProf = smoothstep(
                                    1.0, 1.0 - saturate(soft), nd);
                                float bokeh = lerp(sProf, dProf, coc);

                                // エネルギー保存
                                float energy = (scrR * scrR)
                                             / max(cocR * cocR, 0.0001);

                                // フォグ
                                float fog = exp(
                                    -dist * dist / (_FogDist * _FogDist));

                                // きらめき
                                float tw = 1.0 - _TwinkleAmt
                                    + _TwinkleAmt * (0.5 + 0.5 * sin(
                                        t * _TwinkleSpeed * (1.0 + rnd.x * 2.0)
                                        + rnd.y * 6.2831));

                                float3 bCol = pickColor(cid, lSeed, rnd4);
                                float lumVar = 0.6 + 0.4 * rnd3;
                                float e = bokeh * lBright * energy
                                        * fog * tw * lumVar * cocFade
                                        * sizeBright;
                                col += bCol * e * _Brightness;
                            }
                        }
                    }

                    // ====== 浮遊パーティクル ======
                    if (_FloatDensity > 0.01)
                    {
                        float fgs = gridBase * 0.4;
                        float2 fgUV = worldXZ * fgs;
                        float2 fid = floor(fgUV);

                        [loop]
                        for (int fy = -2; fy <= 2; fy++)
                        {
                            [loop]
                            for (int fx = -2; fx <= 2; fx++)
                            {
                                float2 foff = float2(fx, fy);
                                float2 fcid = fid + foff;
                                float2 frnd = hash22(fcid + 500.0);
                                float frnd3 = hash21(fcid + 577.7);
                                float frnd4 = hash21(fcid + 633.3);

                                if (frnd3 > _FloatDensity) continue;

                                float2 fpXZ = (fcid + frnd) / fgs;
                                float fgh = groundHeight(fpXZ);
                                float fSizeMul = lerp(0.06, 0.12, frnd4);
                                float fwR = _ParticleSize * fSizeMul;
                                float fSizeBright = 0.08 / max(fSizeMul, 0.001);
                                float floatY = fgh + fwR
                                             + _FloatHeight * (0.3 + frnd4 * 0.7);
                                float3 fpW = float3(fpXZ.x, floatY, fpXZ.y);

                                float fdph = t * _DriftSpeed * 0.5
                                           * (0.6 + frnd3) + frnd.x * 6.2831;
                                fpW.x += sin(fdph) * 0.08;
                                fpW.z += sin(fdph * 0.5 + 2.0) * 0.05;
                                fpW.y += sin(fdph * 0.3 + 1.0)
                                       * _FloatHeight * 0.1;

                                if (isOccluded(camPos, fpW)) continue;

                                float fcamZ;
                                float2 fscrP = projectToScreen(
                                    fpW, camPos, cp, sp,
                                    halfTanFov, aspect, fcamZ);
                                if (fcamZ <= 0.01) continue;

                                float fscrR = fwR
                                            / (fcamZ * halfTanFov) * 0.5;
                                float fdist = length(camPos - fpW);
                                float fcoc = saturate(
                                    abs(fdist - _FocalDist) / _FocalDist
                                    * _CoCStr);
                                float fcocR = fscrR * (1.0 + fcoc * 5.0);

                                float fcocFade = 1.0 - smoothstep(0.5, 1.0, fcoc);
                                if (fcocFade < 0.001) continue;

                                float2 fdelta = (uv - fscrP)
                                              * float2(aspect, 1.0);
                                float fdd = length(fdelta);
                                float fnd = fdd / max(fcocR, 0.0001);
                                if (fnd > 1.15) continue;

                                float fsZ = sqrt(max(0.0, 1.0 - fnd * fnd));
                                float fsProf = (fsZ * 0.7 + 0.3)
                                             * step(fnd, 1.0);
                                float fsoft = _Softness + fcoc * 0.3;
                                float fdProf = smoothstep(
                                    1.0, 1.0 - saturate(fsoft), fnd);
                                float fbokeh = lerp(fsProf, fdProf, fcoc);

                                float fenergy = (fscrR * fscrR)
                                              / max(fcocR * fcocR, 0.0001);
                                float ffog = exp(
                                    -fdist * fdist / (_FogDist * _FogDist));
                                float ftw = 1.0 - _TwinkleAmt
                                    + _TwinkleAmt * (0.5 + 0.5 * sin(
                                        t * _TwinkleSpeed
                                        * (0.8 + frnd.x * 1.5)
                                        + frnd.y * 6.2831));

                                float3 fbCol = pickColor(fcid, 500.0, frnd4);
                                float flumVar = 0.5 + 0.5 * frnd3;
                                float fe = fbokeh * fenergy
                                         * ffog * ftw * flumVar * fcocFade
                                         * fSizeBright;
                                col += fbCol * fe * _Brightness;
                            }
                        }
                    }
                }

                // --- トーンマッピング ---
                col *= _Exposure;
                col = 1.0 - exp(-col);
                float luma = dot(col, float3(0.2126, 0.7152, 0.0722));
                col = lerp(luma.xxx, col, _Saturation);
                col = saturate(col);

                float alpha = sprite.a * _Opacity;

                #ifdef UNITY_UI_CLIP_RECT
                alpha *= UnityGet2DClipping(i.worldPosition.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(alpha - 0.001);
                #endif

                return float4(col, alpha);
            }
            ENDCG
        }
    }
}
