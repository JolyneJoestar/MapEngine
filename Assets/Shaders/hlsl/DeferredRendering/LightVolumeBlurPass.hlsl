#ifndef LIGHT_VOLUME__BLUR_PASS_INCLUDE
#define LIGHT_VOLUME__BLUR_PASS_INCLUDE

#include "../Common.hlsl"					
#include "DeferredRenderHelper.hlsl"


TEXTURE2D(_LightVolume);
SAMPLER(sampler_LightVolume);
float4x4 _Dither;

float4 lightVolumeBlurFragment(v2f vert) : SV_TARGET
{
	float2 texelSize = 1.0 / float2(512, 360.0);
	float3 result = 0.0;
	int radius = 4;
	for (int i = -radius; i < radius; i++)
	{
		for (int j = -radius; j < radius; j++)
		{
			float2 offset = float2(float(i), float(j)) * texelSize;
			result += SAMPLE_TEXTURE2D(_LightVolume, sampler_LightVolume, vert.uv + offset).rgb;
		}
	}
	return float4(result / float(radius * radius * 4),1.0);
}

#endif //LIGHT_VOLUME__BLUR_PASS_INCLUDE