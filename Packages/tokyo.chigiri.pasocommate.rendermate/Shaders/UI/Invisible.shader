Shader "RenderMate/UI/Invisible"
{
    Properties
    {
        // uGUI が Image.mainTexture を `_MainTex` にアサインしようとするため必須
        [HideInInspector] _MainTex ("MainTex (uGUI compat)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }

        // 色もデプスも一切書き込まない — フラグメントシェーダーすら不要
        ColorMask 0
        ZWrite Off
        Cull Off

        Pass { }
    }
}
