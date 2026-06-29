#ifndef RENDERMATE_AUDIOLINKSAMPLING_CGINC
#define RENDERMATE_AUDIOLINKSAMPLING_CGINC

// AudioLink 信号サンプリング。キックエンベロープ検出を含む。
// AudioLink.cginc を先に #include しておくこと。
//
// 呼び出し元で以下の uniform を定義済みであること:
//   float _AudioLinkSource;
//   float _AudioLinkKickEnvelope;
//   float _AudioLinkKickThreshold;
//   float _AudioLinkKickGain;
//   float _AudioLinkKickDecayFrames;

float RmSampleAudioLinkSignalRaw(int source, int filteredVuFilter, int historyOffset)
{
    if (source == 1)
    {
        return AudioLinkData(ALPASS_AUDIOLINK + uint2(historyOffset, 0)).r;
    }
    else if (source == 2)
    {
        float lowMid = AudioLinkData(ALPASS_AUDIOLINK + uint2(historyOffset, 1)).r;
        float highMid = AudioLinkData(ALPASS_AUDIOLINK + uint2(historyOffset, 2)).r;
        return (lowMid + highMid) * 0.5;
    }
    else if (source == 3)
    {
        return AudioLinkData(ALPASS_AUDIOLINK + uint2(historyOffset, 3)).r;
    }
    else
    {
        int filter = clamp(filteredVuFilter, 0, 3);
        float4 vu = AudioLinkData(ALPASS_FILTEREDVU_INTENSITY + uint2(filter, 0));
        return (vu.r + vu.b) * 0.5;
    }
}

float RmSampleAudioLinkSignal(int filteredVuFilter)
{
    int source = clamp((int)floor(_AudioLinkSource + 0.5), 0, 3);
    float baseSignal = RmSampleAudioLinkSignalRaw(source, filteredVuFilter, 0);

    float kickMix = saturate(_AudioLinkKickEnvelope);
    if (kickMix <= 0.0 || source == 0)
    {
        return baseSignal;
    }

    const int RM_KICK_HISTORY_MAX = 16;
    int decayFrames = clamp((int)floor(_AudioLinkKickDecayFrames + 0.5), 1, RM_KICK_HISTORY_MAX);
    float threshold = max(_AudioLinkKickThreshold, 0.0);
    float gain = max(_AudioLinkKickGain, 1.0);

    float kickEnv = 0.0;
    [loop]
    for (int i = 0; i < RM_KICK_HISTORY_MAX; i++)
    {
        if (i >= decayFrames)
        {
            break;
        }
        float curr = RmSampleAudioLinkSignalRaw(source, filteredVuFilter, i);
        float prev = RmSampleAudioLinkSignalRaw(source, filteredVuFilter, i + 1);
        float onset = saturate((curr - prev - threshold) * gain);
        float tail = saturate(1.0 - ((float)i / max((float)decayFrames, 1.0)));
        kickEnv = max(kickEnv, onset * tail);
    }

    return lerp(baseSignal, kickEnv, kickMix);
}

#endif
