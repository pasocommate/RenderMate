#ifndef RENDERMATE_MATCAP_CGINC
#define RENDERMATE_MATCAP_CGINC

// Matcap (疑似法線→ビュー空間→matcap UV) ユーティリティ。
// UnityCG.cginc を先に #include しておくこと。
//
// ComputeMatcapUV は以下を呼び出し元で定義済みであること:
//   sampler2D _MatcapNormalTex;
//   float4    _MatcapNormalTex_ST;

// オブジェクト空間の疑似法線をワールド→ビュー変換し、ビュー空間法線の xy*0.5+0.5 を matcap UV として返す。
float2 RmComputeMatcapUVFromNormal(float3 nObj)
{
    float3 nWS = UnityObjectToWorldNormal(nObj);
    float3 nVS = normalize(mul((float3x3)UNITY_MATRIX_V, nWS));
    return nVS.xy * 0.5 + 0.5;
}

// 2D 方向 (dirObjXY) を tilt で倍率スケールし z=1 を被せて疑似法線を作る。
// tilt = 0 → (0,0,1)（純粋な視線反射）、tilt が大きいほど面が外向きに倒れる。
float3 RmBuildMatcapNormal(float2 dirObjXY, float tilt)
{
    return normalize(float3(dirObjXY * tilt, 1.0));
}

// ノーマルマップ摂動を加えた疑似法線から matcap UV を作る。
// サンプリングは tex2Dgrad 前提で、勾配（ミップ選択）側は摂動無しの滑らかな UV から
// 別途計算する想定（＝ RmComputeMatcapUVBase と併用）。
float2 RmComputeMatcapUV(float2 dirObjXY, float tilt, float2 uv, float normalStrength)
{
    float3 nObj = RmBuildMatcapNormal(dirObjXY, tilt);
    float2 nmUV = uv * _MatcapNormalTex_ST.xy + _MatcapNormalTex_ST.zw;
    float3 nm = UnpackNormal(tex2D(_MatcapNormalTex, nmUV));
    nObj = normalize(float3(nObj.xy + nm.xy * normalStrength, nObj.z));
    return RmComputeMatcapUVFromNormal(nObj);
}

// ノーマルマップを通さない基準 matcap UV。ddx/ddy を取るとピクセル間でなめらかな変化が得られ、
// ノーマル摂動で UV が跳ねても tex2Dgrad が過剰に高ミップ（＝ぼけた結果）に落ちなくなる。
float2 RmComputeMatcapUVBase(float2 dirObjXY, float tilt)
{
    return RmComputeMatcapUVFromNormal(RmBuildMatcapNormal(dirObjXY, tilt));
}

#endif
