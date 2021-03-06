#ifndef MY_LEGACY_LIGHT_INCLUDE
#define MY_LEGACY_LIGHT_INCLUDE

#define MAX_VISIBLE_LIGHTS 4

CBUFFER_START(MLightBuffer)
	int MVisibleLightCount;
	float4 MVisibleLightColors[MAX_VISIBLE_LIGHTS];
	float4 MVisibleLightDirecitons[MAX_VISIBLE_LIGHTS];
    float4 MDirectionalLightShadowData[MAX_VISIBLE_LIGHTS];
CBUFFER_END

struct Light
{
    float3 direction;
    float3 color;
	float attenuation;
};

struct SimpleLight
{
	float3 color;
	float attenuation;
};

float SquareDistance(float3 A, float3 B)
{
    return dot(B - A, B - A);
}

float FadedShadowStrength(float distance, float scale, float fade)
{
    return saturate((1.0 - distance * scale) * fade);
}
ShadowData GetShadowData(Surface surfaceWS)
{
    ShadowData data;
    data.strength = FadedShadowStrength(surfaceWS.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    data.cascadeBlend = 1.0;
    int i;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSphere[i];
        float distanceSqr = SquareDistance(surfaceWS.position, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
            if (i == _CascadeCount - 1)
            {
                data.strength *= fade;
            }
            else
            {
                data.cascadeBlend = fade;
            }
            break;
        }         
    }
    if(i == _CascadeCount)
    {
        data.strength = 0.0;
    }
#if defined(_CASCADE_BLEND_DITHER)
    else if (data.cascadeBlend < surfaceWS.dither) {
	    i += 1;
    }
#endif
#if !defined(_CASCADE_BLEND_SOFT)
    data.cascadeBlend = 1.0;
#endif
    data.cascadeIndex = i;
    return data;
}

ShadowData GetShadowData(float3 posWS)
{
    ShadowData data;
    data.strength = FadedShadowStrength(-TransformWorldToView(posWS).z, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    data.cascadeBlend = 1.0;
    int i;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSphere[i];
        float distanceSqr = SquareDistance(posWS, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
            if (i == _CascadeCount - 1)
            {
                data.strength *= fade;
            }
            else
            {
                data.cascadeBlend = fade;
            }
            break;
        }
    }
    if (i == _CascadeCount)
    {
        data.strength = 0.0;
    }
#if !defined(_CASCADE_BLEND_SOFT)
    data.cascadeBlend = 1.0;
#endif
    data.cascadeIndex = i;
    return data;
}

DirectionalShadowData GetDirectionalShadowData(int lightIndex, ShadowData shadowData)
{
    DirectionalShadowData data;
    data.strength = MDirectionalLightShadowData[lightIndex].x * shadowData.strength;
    data.tileIndex = MDirectionalLightShadowData[lightIndex].y + shadowData.cascadeIndex;
    data.normalBias = MDirectionalLightShadowData[lightIndex].z;
    return data;
}

int GetDirectionLightCount()
{
    return MVisibleLightCount;
}

Light GetDirectionLight(int index, Surface surfaceWS, ShadowData shadowdata)
{
    Light light;
    light.color = MVisibleLightColors[index].xyz;
    light.direction = MVisibleLightDirecitons[index].xyz;
    DirectionalShadowData dirShadowData = GetDirectionalShadowData(index, shadowdata);
    light.attenuation = GetDirectionalShadowAttenuation(dirShadowData, shadowdata, surfaceWS);
//  light.attenuation = shadowdata.cascadeIndex * 0.25;
    return light;
}

SimpleLight GetSimpleLight(int index, float3 posWS, ShadowData shadowData)
{
	SimpleLight sLight;
	sLight.color = MVisibleLightColors[index].xyz;
	DirectionalShadowData dirShadowData = GetDirectionalShadowData(index, shadowData);
	sLight.attenuation = GetLightAttenuation(dirShadowData, shadowData, posWS);
	return sLight;
}

float IncomingLightAttenua(Surface surface, Light light)
{
	return saturate(dot(surface.normal, light.direction));
}

float3 IncomingLight(Surface surface,Light light)
{
    return saturate(IncomingLightAttenua(surface, light)) * light.attenuation * light.color;
}


//float3 GetLighting(Surface surface, Light light)
//{
//    return IncomingLight(surface, light) * surface.color;
//}

//float3 GetLighting(Surface surface)
//{
//    float3 color = 0.0;
//    for (int i = 0; i < GetDirectionLightCount(); i++)
//    {
//        color += GetLighting(surface, GetDirectionLight(i, surface));
//    }
//    return color;
//}

#endif //MY_LEGACY_LIGHT_INCLUDE