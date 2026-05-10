#ifndef RENDERMATE_BLURDISK_CGINC
#define RENDERMATE_BLURDISK_CGINC

// Vogel ディスク: ゴールデンアングルらせんで均一分布した 32 サンプル点。
// ガウス重み付けで中心ほど強く、端は自然にフェードアウトする。
//
// 呼び出し元で以下を定義済みであること:
//   #define RM_BLUR_ENABLED 1
//   sampler2D <grabTex>;
//   float4    <grabTex>_TexelSize;
//   float     _BlurRadius;

#if defined(RM_BLUR_ENABLED)

#define RM_BLUR_SAMPLES 32

static const float2 rmBlurDisk[RM_BLUR_SAMPLES] = {
    float2(+0.04530, +0.11650),
    float2(-0.19416, -0.09580),
    float2(+0.26837, -0.07812),
    float2(-0.17170, +0.28265),
    float2(-0.07293, -0.36784),
    float2(+0.33415, +0.24539),
    float2(-0.44806, +0.04867),
    float2(+0.31957, -0.36366),
    float2(+0.01065, +0.51528),
    float2(-0.37627, -0.39407),
    float2(+0.57154, +0.03828),
    float2(-0.46811, +0.37450),
    float2(+0.09612, -0.61756),
    float2(+0.35986, +0.54071),
    float2(-0.65354, -0.16128),
    float2(+0.61088, -0.33347),
    float2(-0.23234, +0.67944),
    float2(-0.29623, -0.67759),
    float2(+0.69518, +0.30797),
    float2(-0.73986, +0.24897),
    float2(+0.38693, -0.70065),
    float2(+0.19251, +0.79675),
    float2(-0.69578, -0.46798),
    float2(+0.84739, -0.12767),
    float2(-0.54995, +0.68058),
    float2(-0.05531, -0.89096),
    float2(+0.65510, +0.63164),
    float2(-0.92672, -0.02368),
    float2(+0.71193, -0.61950),
    float2(-0.10834, +0.95401),
    float2(-0.57403, -0.78970),
    float2(+0.97226, +0.19771),
};

static const float rmBlurWeights[RM_BLUR_SAMPLES] = {
    0.969233, 0.910510, 0.855345, 0.803523,
    0.754840, 0.709106, 0.666144, 0.625784,
    0.587870, 0.552252, 0.518793, 0.487361,
    0.457833, 0.430095, 0.404037, 0.379557,
    0.356561, 0.334958, 0.314664, 0.295599,
    0.277690, 0.260866, 0.245061, 0.230213,
    0.216265, 0.203162, 0.190853, 0.179290,
    0.168427, 0.158223, 0.148637, 0.139631,
};

static const float rmBlurWeightRcp = 1.0 / 13.832384;

// grabTex と texelSize を引数で受け取り、Vogel ディスクぼかしを適用する。
float3 RmSampleBlurredGrab(sampler2D grabTex, float2 texelSize, float4 grabPos)
{
    float2 uv = grabPos.xy / grabPos.w;
    float2 px = texelSize * _BlurRadius;

    float3 col = float3(0, 0, 0);
    UNITY_UNROLL
    for (int i = 0; i < RM_BLUR_SAMPLES; i++)
    {
        col += tex2D(grabTex, uv + rmBlurDisk[i] * px).rgb * rmBlurWeights[i];
    }
    return col * rmBlurWeightRcp;
}

#endif // RM_BLUR_ENABLED

#endif
