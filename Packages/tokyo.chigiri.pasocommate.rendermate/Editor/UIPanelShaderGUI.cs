using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace RenderMate.Editor
{
    [InitializeOnLoad]
    public class UIPanelShaderGUI : ShaderGUI
    {
        static Mesh s_previewQuad;
        static PreviewRenderUtility s_previewUtil;
        static GUIStyle s_sectionHeaderStyle;

        static UIPanelShaderGUI()
        {
            AssemblyReloadEvents.beforeAssemblyReload += CleanupPreview;
        }

        static void CleanupPreview()
        {
            if (s_previewUtil != null)
            {
                s_previewUtil.Cleanup();
                s_previewUtil = null;
            }
        }

        static readonly Dictionary<string, string> Tooltips = new Dictionary<string, string>
        {
            // ベースカラー
            { "_BaseTex", "パネルに貼るベーステクスチャ" },
            { "_UseMainTex", "RawImage の _MainTex をサンプリングする" },
            { "_Gamma", "Linear 色空間で _MainTex サンプルに適用するガンマ補正指数。1 で補正なし" },
            { "_FlipY", "_MainTex サンプリング時に UV の Y 軸を反転する" },
            { "_UseMSDF", "ベーステクスチャを MSDF (Multi-channel Signed Distance Field) として解釈する" },
            { "_MSDFPixelRange", "MSDF テクスチャ生成時に指定した pxRange の値。アンチエイリアス幅に影響する" },
            { "_Color", "ベースカラーに乗算する色 (HDR 対応)" },
            { "_MatcapOn", "Matcap (疑似環境マッピング) を有効にする" },
            { "_BaseMatcapTex", "パネル本体に加算合成する Matcap テクスチャ" },
            { "_BaseMatcapColor", "Base Matcap の色味と強度。アルファで加算量を調整" },
            { "_BaseMatcapTilt", "0 = 平面的、正で凸ドーム・負で凹お椀。絶対値が大きいほど傾きが強くなる" },
            { "_BaseMatcapVertexColorInfluence", "0 = Matcap をそのまま加算、1 = Image.Color を Matcap に乗算してから加算" },
            { "_BaseMatcapNormalStrength", "ノーマルマップによる Base Matcap の揺らぎ強度" },
            { "_MatcapNormalTex", "Base / Border 共通のノーマルマップ。タイリング可能" },
            // グラデーション
            { "_GRADIENT", "なし / 線形 / 放射状 から選択。ベースカラーに乗算合成される" },
            { "_GradientColor1", "グラデーション開始色 (HDR)" },
            { "_GradientColor2", "グラデーション終了色 (HDR)" },
            { "_GradientAngle", "線形グラデーションの角度 (度)。0 = 上→下" },
            { "_GradientCenter", "放射状グラデーションの中心 (UV 座標、0.5 = 中央)" },
            { "_GradientRange", "LINEAR: x=開始位置 y=終了位置 / RADIAL: x=内側半径 y=外側半径 zw=楕円のアスペクト比" },
            // コーナー形状
            { "_CORNER", "パネルのコーナー形状。SDF でアンチエイリアス付き描画される" },
            { "_CornerSize", "角丸 / 八角形の面取りサイズ (ピクセル単位)" },
            // 枠線
            { "_BorderColor", "枠線の色 (HDR 対応)" },
            { "_BorderWidth", "枠線の太さ (ピクセル単位)。0 で枠線なし" },
            { "_BorderVertexColorInfluence", "0 = Image.Color を無視、1 = 完全に乗算。中間値で線形に混合" },
            { "_BorderRingCount", "同心リングの本数。1 で従来の単一ボーダー" },
            { "_BorderGap", "リング間の隙間 (ピクセル単位)" },
            { "_AudioLinkBorderFilter", "Border 用 FilteredVU の平滑化レベル (0=最も遅い, 3=最も速い)" },
            { "_AudioLinkBorderIntensity", "Border の表示本数を RMS で制御する強度。0=無効, 1=完全制御" },
            { "_BorderMatcapTex", "枠線に加算合成する Matcap テクスチャ" },
            { "_BorderMatcapColor", "Border Matcap の色味と強度。アルファで加算量を調整" },
            { "_BorderMatcapTilt", "0 = 平面的、正で外向き・負で内向きに傾く。絶対値が大きいほどエッジ反射に近づく" },
            { "_BorderMatcapVertexColorInfluence", "0 = Matcap をそのまま加算、1 = Image.Color を Matcap に乗算してから加算" },
            { "_BorderMatcapNormalStrength", "ノーマルマップによる Border Matcap の揺らぎ強度" },
            // ディゾルブ
            { "_DISSOLVE", "なし / 線形 / 放射状 から選択。閾値に基づいてアルファを消す" },
            { "_DissolveThreshold", "0 = 全表示、1 = 全消去、-1 = 逆方向から全消去。この値を境にフェードする" },
            { "_DissolveSoftness", "消え際のぼかし幅。大きいほどなだらかに消える" },
            { "_DissolveAngle", "線形ディゾルブの方向角度 (度)" },
            { "_DissolveCenter", "放射状ディゾルブの中心 (UV 座標)" },
            { "_DissolveRadius", "放射状ディゾルブの半径 (UV 単位)" },
            { "_DissolveEdgeColor", "消え際のエッジに乗せる色 (HDR 対応)" },
            { "_DissolveEdgeVertexColorInfluence", "0 = エッジ色をそのまま使用、1 = Image.Color をエッジ色に乗算" },
            // 背景ぼかし
            { "_BlurOn", "GrabPass を使ったすりガラス風の背景ぼかしを有効にする (PC 限定)" },
            { "_BlurRadius", "ぼかしの半径。値が大きいほど強くぼける" },
            // AudioLink
            { "_AudioLinkFilterIntensity", "FilteredVU の平滑化レベル (0=最も遅い, 3=最も速い)" },
            { "_AudioLinkShiftStart", "RMS 音量がグラデーション開始点をどれだけシフトするか" },
            { "_AudioLinkShiftEnd", "RMS 音量がグラデーション終了点をどれだけシフトするか" },
            { "_AudioLinkSource", "AudioLink 入力ソース。Filtered VU RMS / Bass / Mid / Treble から選択" },
            { "_AudioLinkKickEnvelope", "キック包絡線の適用率。0=無効, 1=キック頭で最大→余韻減衰を全面適用" },
            { "_AudioLinkKickThreshold", "キック検出しきい値。小さいほど反応しやすい" },
            { "_AudioLinkKickGain", "キック検出の立ち上がり増幅。大きいほど頭で最大に触れやすい" },
            { "_AudioLinkKickDecayFrames", "キック頭から減衰する余韻フレーム数 (最大16)" },
        };

        static readonly string[] ToggleKeywords =
        {
            "_USE_MSDF",
            "_USE_MAINTEX",
            "_MATCAP_ON",
            "_BLUR_ON",
        };

        static readonly string[] ToggleProperties =
        {
            "_UseMSDF",
            "_UseMainTex",
            "_MatcapOn",
            "_BlurOn",
        };

        static Mesh PreviewQuad
        {
            get
            {
                if (s_previewQuad == null)
                    s_previewQuad = BuildPreviewQuad();
                return s_previewQuad;
            }
        }

        static Mesh BuildPreviewQuad()
        {
            float half = 128f;
            var mesh = new Mesh { name = "UIPanel Preview Quad", hideFlags = HideFlags.HideAndDontSave };
            mesh.vertices = new[]
            {
                new Vector3(-0.5f, -0.5f, 0),
                new Vector3( 0.5f, -0.5f, 0),
                new Vector3( 0.5f,  0.5f, 0),
                new Vector3(-0.5f,  0.5f, 0),
            };
            mesh.uv = new[]
            {
                new Vector2(0, 0),
                new Vector2(1, 0),
                new Vector2(1, 1),
                new Vector2(0, 1),
            };
            mesh.uv2 = new[]
            {
                new Vector2(-half, -half),
                new Vector2( half, -half),
                new Vector2( half,  half),
                new Vector2(-half,  half),
            };
            mesh.colors = new[]
            {
                Color.white,
                Color.white,
                Color.white,
                Color.white,
            };
            mesh.triangles = new[] { 0, 1, 2, 0, 2, 3 };
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        static PreviewRenderUtility GetPreviewUtil()
        {
            if (s_previewUtil == null)
                s_previewUtil = new PreviewRenderUtility();
            return s_previewUtil;
        }

        static void SetupCamera(Camera cam)
        {
            cam.transform.position = new Vector3(0, 0, -1.2f);
            cam.transform.rotation = Quaternion.identity;
            cam.orthographic = true;
            cam.orthographicSize = 0.55f;
            cam.nearClipPlane = 0.1f;
            cam.farClipPlane = 10f;
        }

        static void RenderPreview(Material mat, Rect r, GUIStyle background)
        {
            if (Event.current.type != EventType.Repaint)
                return;
            if (mat == null)
                return;

            var util = GetPreviewUtil();
            util.BeginPreview(r, background);
            SetupCamera(util.camera);
            util.DrawMesh(PreviewQuad, Matrix4x4.identity, mat, 0);
            util.Render();
            var tex = util.EndPreview();
            GUI.DrawTexture(r, tex, ScaleMode.StretchToFill, true);
        }

        static void SyncToggleKeywords(Material mat)
        {
            for (int i = 0; i < ToggleProperties.Length; i++)
            {
                if (!mat.HasProperty(ToggleProperties[i]))
                    continue;
                if (mat.GetFloat(ToggleProperties[i]) > 0.5f)
                    mat.EnableKeyword(ToggleKeywords[i]);
                else
                    mat.DisableKeyword(ToggleKeywords[i]);
            }
        }

        static GUIStyle SectionHeaderStyle
        {
            get
            {
                if (s_sectionHeaderStyle == null)
                {
                    s_sectionHeaderStyle = new GUIStyle(EditorStyles.boldLabel)
                    {
                        fontSize = 12,
                        padding = new RectOffset(6, 6, 2, 2),
                    };
                    var bg = new Texture2D(1, 1, TextureFormat.RGBA32, false) { hideFlags = HideFlags.HideAndDontSave };
                    bg.SetPixel(0, 0, new Color(0f, 0f, 0f, 0.3f));
                    bg.Apply();
                    s_sectionHeaderStyle.normal.background = bg;
                }
                return s_sectionHeaderStyle;
            }
        }

        static void DrawSectionHeader(string label)
        {
            EditorGUILayout.Space(6f);
            EditorGUILayout.LabelField(label, SectionHeaderStyle);
            EditorGUILayout.Space(2f);
        }

        static void DrawProp(MaterialEditor materialEditor, MaterialProperty prop, string label = null)
        {
            if (prop == null)
                return;
            string displayLabel = label ?? prop.displayName;
            Tooltips.TryGetValue(prop.name, out string tooltip);
            materialEditor.ShaderProperty(prop, new GUIContent(displayLabel, tooltip));
        }

        static void DrawSubHeading(string label)
        {
            EditorGUILayout.Space(2f);
            EditorGUILayout.LabelField(label, EditorStyles.boldLabel);
        }

        static bool IsToggleOn(MaterialProperty prop)
        {
            return prop != null && (prop.hasMixedValue || prop.floatValue > 0.5f);
        }

        static bool IsMode(MaterialProperty prop, int mode)
        {
            return prop != null && (prop.hasMixedValue || Mathf.RoundToInt(prop.floatValue) == mode);
        }

        static bool IsNotMode(MaterialProperty prop, int mode)
        {
            return prop != null && (prop.hasMixedValue || Mathf.RoundToInt(prop.floatValue) != mode);
        }

        static void DrawBaseColorSection(
            MaterialEditor materialEditor,
            MaterialProperty baseTex,
            MaterialProperty useMainTex,
            MaterialProperty gamma,
            MaterialProperty flipY,
            MaterialProperty useMSDF,
            MaterialProperty msdfPixelRange,
            MaterialProperty color)
        {
            DrawSectionHeader("ベースカラー");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, useMainTex);
            if (IsToggleOn(useMainTex))
            {
                DrawProp(materialEditor, gamma);
                DrawProp(materialEditor, flipY);
            }
            else
            {
                DrawProp(materialEditor, baseTex);
                DrawProp(materialEditor, useMSDF);
                if (IsToggleOn(useMSDF))
                    DrawProp(materialEditor, msdfPixelRange);
            }

            DrawProp(materialEditor, color);
            EditorGUI.indentLevel--;
        }

        static void DrawMatcapSection(
            MaterialEditor materialEditor,
            MaterialProperty matcapOn,
            MaterialProperty matcapNormalTex,
            MaterialProperty baseMatcapTex,
            MaterialProperty baseMatcapColor,
            MaterialProperty baseMatcapTilt,
            MaterialProperty baseMatcapVertexColorInfluence,
            MaterialProperty baseMatcapNormalStrength,
            MaterialProperty borderMatcapTex,
            MaterialProperty borderMatcapColor,
            MaterialProperty borderMatcapTilt,
            MaterialProperty borderMatcapVertexColorInfluence,
            MaterialProperty borderMatcapNormalStrength)
        {
            DrawSectionHeader("Matcap");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, matcapOn);
            if (IsToggleOn(matcapOn))
            {
                DrawProp(materialEditor, matcapNormalTex, "Normal Map");

                DrawSubHeading("Base");
                EditorGUI.indentLevel++;
                DrawProp(materialEditor, baseMatcapTex, "Texture");
                DrawProp(materialEditor, baseMatcapColor, "Color");
                DrawProp(materialEditor, baseMatcapTilt, "Tilt");
                DrawProp(materialEditor, baseMatcapVertexColorInfluence, "Image.Color Influence");
                DrawProp(materialEditor, baseMatcapNormalStrength, "Normal Strength");
                EditorGUI.indentLevel--;

                DrawSubHeading("Border");
                EditorGUI.indentLevel++;
                DrawProp(materialEditor, borderMatcapTex, "Texture");
                DrawProp(materialEditor, borderMatcapColor, "Color");
                DrawProp(materialEditor, borderMatcapTilt, "Tilt");
                DrawProp(materialEditor, borderMatcapVertexColorInfluence, "Image.Color Influence");
                DrawProp(materialEditor, borderMatcapNormalStrength, "Normal Strength");
                EditorGUI.indentLevel--;
            }
            EditorGUI.indentLevel--;
        }

        static void DrawBlurSection(
            MaterialEditor materialEditor,
            MaterialProperty blurOn,
            MaterialProperty blurRadius)
        {
            DrawSectionHeader("背景ぼかし");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, blurOn);
            if (IsToggleOn(blurOn))
                DrawProp(materialEditor, blurRadius, "Radius");
            EditorGUI.indentLevel--;
        }

        static void DrawGradientSection(
            MaterialEditor materialEditor,
            MaterialProperty gradientMode,
            MaterialProperty gradientColor1,
            MaterialProperty gradientColor2,
            MaterialProperty gradientAngle,
            MaterialProperty gradientCenter,
            MaterialProperty gradientRange,
            MaterialProperty audioLinkSource,
            MaterialProperty audioLinkFilterIntensity,
            MaterialProperty audioLinkShiftStart,
            MaterialProperty audioLinkShiftEnd,
            MaterialProperty audioLinkKickEnvelope,
            MaterialProperty audioLinkKickThreshold,
            MaterialProperty audioLinkKickGain,
            MaterialProperty audioLinkKickDecayFrames)
        {
            DrawSectionHeader("グラデーション");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, gradientMode, "Mode");

            if (IsNotMode(gradientMode, 0))
            {
                DrawProp(materialEditor, gradientColor1, "Color 1");
                DrawProp(materialEditor, gradientColor2, "Color 2");

                if (IsMode(gradientMode, 1))
                {
                    DrawProp(materialEditor, gradientAngle, "Angle");
                    DrawProp(materialEditor, gradientRange, "Range");
                }
                if (IsMode(gradientMode, 2))
                {
                    DrawProp(materialEditor, gradientCenter, "Center");
                    DrawProp(materialEditor, gradientRange, "Radius");
                }

                DrawSubHeading("AudioLink");
                EditorGUI.indentLevel++;
                DrawProp(materialEditor, audioLinkSource, "Source");
                bool useFilteredVu = audioLinkSource != null && (audioLinkSource.hasMixedValue || Mathf.RoundToInt(audioLinkSource.floatValue) == 0);
                if (useFilteredVu)
                    DrawProp(materialEditor, audioLinkFilterIntensity, "Filter Intensity");
                DrawProp(materialEditor, audioLinkShiftStart, "Shift Start");
                DrawProp(materialEditor, audioLinkShiftEnd, "Shift End");

                bool canUseKickEnvelope = audioLinkSource != null && (audioLinkSource.hasMixedValue || Mathf.RoundToInt(audioLinkSource.floatValue) != 0);
                if (canUseKickEnvelope)
                {
                    DrawSubHeading("Kick Envelope");
                    EditorGUI.indentLevel++;
                    DrawProp(materialEditor, audioLinkKickEnvelope, "Amount");
                    bool showKickParams = audioLinkKickEnvelope != null && (audioLinkKickEnvelope.hasMixedValue || audioLinkKickEnvelope.floatValue > 0.0f);
                    if (showKickParams)
                    {
                        DrawProp(materialEditor, audioLinkKickThreshold, "Threshold");
                        DrawProp(materialEditor, audioLinkKickGain, "Gain");
                        DrawProp(materialEditor, audioLinkKickDecayFrames, "Decay Frames");
                    }
                    EditorGUI.indentLevel--;
                }
                EditorGUI.indentLevel--;
            }
            EditorGUI.indentLevel--;
        }

        static void DrawCornerSection(
            MaterialEditor materialEditor,
            MaterialProperty cornerMode,
            MaterialProperty cornerSize)
        {
            DrawSectionHeader("コーナー形状");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, cornerMode, "Shape");
            if (IsNotMode(cornerMode, 0))
                DrawProp(materialEditor, cornerSize, "Size");
            EditorGUI.indentLevel--;
        }

        static void DrawBorderSection(
            MaterialEditor materialEditor,
            MaterialProperty borderColor,
            MaterialProperty borderWidth,
            MaterialProperty borderVertexColorInfluence,
            MaterialProperty borderRingCount,
            MaterialProperty borderGap,
            MaterialProperty audioLinkSource,
            MaterialProperty audioLinkBorderFilter,
            MaterialProperty audioLinkBorderIntensity,
            MaterialProperty audioLinkKickEnvelope,
            MaterialProperty audioLinkKickThreshold,
            MaterialProperty audioLinkKickGain,
            MaterialProperty audioLinkKickDecayFrames)
        {
            DrawSectionHeader("枠線");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, borderColor, "Color");
            DrawProp(materialEditor, borderWidth, "Width");
            DrawProp(materialEditor, borderVertexColorInfluence, "Image.Color Influence");
            DrawProp(materialEditor, borderRingCount, "Ring Count");

            bool showRingOptions = borderRingCount != null && (borderRingCount.hasMixedValue || borderRingCount.floatValue > 1.0f);
            if (showRingOptions)
            {
                DrawProp(materialEditor, borderGap, "Ring Gap");

                DrawSubHeading("AudioLink");
                EditorGUI.indentLevel++;
                DrawProp(materialEditor, audioLinkSource, "Source");
                bool useFilteredVu = audioLinkSource != null && (audioLinkSource.hasMixedValue || Mathf.RoundToInt(audioLinkSource.floatValue) == 0);
                if (useFilteredVu)
                    DrawProp(materialEditor, audioLinkBorderFilter, "Filter");
                DrawProp(materialEditor, audioLinkBorderIntensity, "Intensity");

                bool canUseKickEnvelope = audioLinkSource != null && (audioLinkSource.hasMixedValue || Mathf.RoundToInt(audioLinkSource.floatValue) != 0);
                if (canUseKickEnvelope)
                {
                    DrawSubHeading("Kick Envelope");
                    EditorGUI.indentLevel++;
                    DrawProp(materialEditor, audioLinkKickEnvelope, "Amount");
                    bool showKickParams = audioLinkKickEnvelope != null && (audioLinkKickEnvelope.hasMixedValue || audioLinkKickEnvelope.floatValue > 0.0f);
                    if (showKickParams)
                    {
                        DrawProp(materialEditor, audioLinkKickThreshold, "Threshold");
                        DrawProp(materialEditor, audioLinkKickGain, "Gain");
                        DrawProp(materialEditor, audioLinkKickDecayFrames, "Decay Frames");
                    }
                    EditorGUI.indentLevel--;
                }
                EditorGUI.indentLevel--;
            }
            EditorGUI.indentLevel--;
        }

        static void DrawDissolveSection(
            MaterialEditor materialEditor,
            MaterialProperty dissolveMode,
            MaterialProperty dissolveThreshold,
            MaterialProperty dissolveSoftness,
            MaterialProperty dissolveAngle,
            MaterialProperty dissolveCenter,
            MaterialProperty dissolveRadius,
            MaterialProperty dissolveEdgeColor,
            MaterialProperty dissolveEdgeVertexColorInfluence)
        {
            DrawSectionHeader("ディゾルブ");
            EditorGUI.indentLevel++;
            DrawProp(materialEditor, dissolveMode, "Mode");

            if (IsNotMode(dissolveMode, 0))
            {
                DrawProp(materialEditor, dissolveThreshold, "Threshold");
                DrawProp(materialEditor, dissolveSoftness, "Softness");

                if (IsMode(dissolveMode, 1))
                    DrawProp(materialEditor, dissolveAngle, "Angle");
                if (IsMode(dissolveMode, 2))
                {
                    DrawProp(materialEditor, dissolveCenter, "Center");
                    DrawProp(materialEditor, dissolveRadius, "Radius");
                }

                DrawProp(materialEditor, dissolveEdgeColor, "Edge Color");
                DrawProp(materialEditor, dissolveEdgeVertexColorInfluence, "Edge Image.Color Influence");
            }
            EditorGUI.indentLevel--;
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            EditorGUI.BeginChangeCheck();

            materialEditor.SetDefaultGUIWidths();

            var baseTex = FindProperty("_BaseTex", properties, false);
            var useMainTex = FindProperty("_UseMainTex", properties, false);
            var gamma = FindProperty("_Gamma", properties, false);
            var flipY = FindProperty("_FlipY", properties, false);
            var useMSDF = FindProperty("_UseMSDF", properties, false);
            var msdfPixelRange = FindProperty("_MSDFPixelRange", properties, false);
            var color = FindProperty("_Color", properties, false);
            var matcapOn = FindProperty("_MatcapOn", properties, false);
            var baseMatcapTex = FindProperty("_BaseMatcapTex", properties, false);
            var baseMatcapColor = FindProperty("_BaseMatcapColor", properties, false);
            var baseMatcapTilt = FindProperty("_BaseMatcapTilt", properties, false);
            var baseMatcapVertexColorInfluence = FindProperty("_BaseMatcapVertexColorInfluence", properties, false);
            var baseMatcapNormalStrength = FindProperty("_BaseMatcapNormalStrength", properties, false);
            var matcapNormalTex = FindProperty("_MatcapNormalTex", properties, false);

            var gradientMode = FindProperty("_GRADIENT", properties, false);
            var gradientColor1 = FindProperty("_GradientColor1", properties, false);
            var gradientColor2 = FindProperty("_GradientColor2", properties, false);
            var gradientAngle = FindProperty("_GradientAngle", properties, false);
            var gradientCenter = FindProperty("_GradientCenter", properties, false);
            var gradientRange = FindProperty("_GradientRange", properties, false);

            var cornerMode = FindProperty("_CORNER", properties, false);
            var cornerSize = FindProperty("_CornerSize", properties, false);

            var borderColor = FindProperty("_BorderColor", properties, false);
            var borderWidth = FindProperty("_BorderWidth", properties, false);
            var borderVertexColorInfluence = FindProperty("_BorderVertexColorInfluence", properties, false);
            var borderRingCount = FindProperty("_BorderRingCount", properties, false);
            var borderGap = FindProperty("_BorderGap", properties, false);
            var audioLinkBorderFilter = FindProperty("_AudioLinkBorderFilter", properties, false);
            var audioLinkBorderIntensity = FindProperty("_AudioLinkBorderIntensity", properties, false);
            var borderMatcapTex = FindProperty("_BorderMatcapTex", properties, false);
            var borderMatcapColor = FindProperty("_BorderMatcapColor", properties, false);
            var borderMatcapTilt = FindProperty("_BorderMatcapTilt", properties, false);
            var borderMatcapVertexColorInfluence = FindProperty("_BorderMatcapVertexColorInfluence", properties, false);
            var borderMatcapNormalStrength = FindProperty("_BorderMatcapNormalStrength", properties, false);

            var dissolveMode = FindProperty("_DISSOLVE", properties, false);
            var dissolveThreshold = FindProperty("_DissolveThreshold", properties, false);
            var dissolveSoftness = FindProperty("_DissolveSoftness", properties, false);
            var dissolveAngle = FindProperty("_DissolveAngle", properties, false);
            var dissolveCenter = FindProperty("_DissolveCenter", properties, false);
            var dissolveRadius = FindProperty("_DissolveRadius", properties, false);
            var dissolveEdgeColor = FindProperty("_DissolveEdgeColor", properties, false);
            var dissolveEdgeVertexColorInfluence = FindProperty("_DissolveEdgeVertexColorInfluence", properties, false);

            var blurOn = FindProperty("_BlurOn", properties, false);
            var blurRadius = FindProperty("_BlurRadius", properties, false);

            var audioLinkFilterIntensity = FindProperty("_AudioLinkFilterIntensity", properties, false);
            var audioLinkShiftStart = FindProperty("_AudioLinkShiftStart", properties, false);
            var audioLinkShiftEnd = FindProperty("_AudioLinkShiftEnd", properties, false);
            var audioLinkSource = FindProperty("_AudioLinkSource", properties, false);
            var audioLinkKickEnvelope = FindProperty("_AudioLinkKickEnvelope", properties, false);
            var audioLinkKickThreshold = FindProperty("_AudioLinkKickThreshold", properties, false);
            var audioLinkKickGain = FindProperty("_AudioLinkKickGain", properties, false);
            var audioLinkKickDecayFrames = FindProperty("_AudioLinkKickDecayFrames", properties, false);

            DrawBaseColorSection(
                materialEditor,
                baseTex,
                useMainTex,
                gamma,
                flipY,
                useMSDF,
                msdfPixelRange,
                color);
            DrawGradientSection(
                materialEditor,
                gradientMode,
                gradientColor1,
                gradientColor2,
                gradientAngle,
                gradientCenter,
                gradientRange,
                audioLinkSource,
                audioLinkFilterIntensity,
                audioLinkShiftStart,
                audioLinkShiftEnd,
                audioLinkKickEnvelope,
                audioLinkKickThreshold,
                audioLinkKickGain,
                audioLinkKickDecayFrames);
            DrawCornerSection(materialEditor, cornerMode, cornerSize);
            DrawBorderSection(
                materialEditor,
                borderColor,
                borderWidth,
                borderVertexColorInfluence,
                borderRingCount,
                borderGap,
                audioLinkSource,
                audioLinkBorderFilter,
                audioLinkBorderIntensity,
                audioLinkKickEnvelope,
                audioLinkKickThreshold,
                audioLinkKickGain,
                audioLinkKickDecayFrames);
            DrawMatcapSection(
                materialEditor,
                matcapOn,
                matcapNormalTex,
                baseMatcapTex,
                baseMatcapColor,
                baseMatcapTilt,
                baseMatcapVertexColorInfluence,
                baseMatcapNormalStrength,
                borderMatcapTex,
                borderMatcapColor,
                borderMatcapTilt,
                borderMatcapVertexColorInfluence,
                borderMatcapNormalStrength);
            DrawBlurSection(materialEditor, blurOn, blurRadius);
            DrawDissolveSection(
                materialEditor,
                dissolveMode,
                dissolveThreshold,
                dissolveSoftness,
                dissolveAngle,
                dissolveCenter,
                dissolveRadius,
                dissolveEdgeColor,
                dissolveEdgeVertexColorInfluence);

            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in materialEditor.targets)
                    SyncToggleKeywords((Material)obj);
            }

            EditorGUILayout.Space();
            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
        }

        public override void OnMaterialPreviewGUI(MaterialEditor materialEditor, Rect r, GUIStyle background)
        {
            RenderPreview(materialEditor.target as Material, r, background);
        }

        public override void OnMaterialInteractivePreviewGUI(MaterialEditor materialEditor, Rect r, GUIStyle background)
        {
            RenderPreview(materialEditor.target as Material, r, background);
        }

        public override void OnClosed(Material material)
        {
            if (s_previewUtil != null)
            {
                s_previewUtil.Cleanup();
                s_previewUtil = null;
            }
        }
    }
}
