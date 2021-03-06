#ifndef MY_LEGACY_LIGHT_PASS_INCLUDE
#define MY_LEGACY_LIGHT_PASS_INCLUDE

#include "Common.hlsl"					
#include "MyLegacySurface.hlsl"
#include "Shadows.hlsl"
#include "GI.hlsl"
#include "MyLegacyLight.hlsl"
#include "Lighting.hlsl"
#include "LitInput.hlsl"


struct MVertexIn {
	float3 positionOS : POSITION;
	float3 normalOS : NORMAL;
	float2 uv : TEXCOORD0;
    GI_ATTRIBUTE_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct MVertexOut {
	float4 positionCS : SV_POSITION;
	float3 positionWS : VAR_POSITION;
	float3 normal : VAR_NORMAL;
	float2 uv : VAR_BASE_UV;
    GI_VARYINGS_DATA
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

float3 CalculateDiffuseFactor(int index, float3 normal)
{
	float3 diffuseLight = MVisibleLightColors[index].rgb;
	float3 direction = MVisibleLightDirecitons[index].xyz;
	return saturate(dot(normalize(direction), normalize(normal))) * diffuseLight;
}


MVertexOut LegacyVertex(MVertexIn inVert)
{

	MVertexOut vert;
	UNITY_SETUP_INSTANCE_ID(inVert);
	UNITY_TRANSFER_INSTANCE_ID(inVert, vert);
    TRANSFER_GI_DATA(inVert, vert);
	vert.positionWS = TransformObjectToWorld(inVert.positionOS);
	vert.positionCS = TransformWorldToHClip(vert.positionWS);

	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, MTexture_ST);
	vert.uv = inVert.uv * baseST.xy + baseST.zw;
	vert.normal = TransformObjectToWorldNormal(inVert.normalOS);
	return vert;
}

float4 LegacyFragment(MVertexOut vert) : SV_TARGET
{
	UNITY_SETUP_INSTANCE_ID(vert);
    
    float4 texColor = GetBase(vert.uv);
	Surface surface;
	surface.position = vert.positionWS;
	surface.normal = normalize(vert.normal);
	surface.viewDirection = normalize(_WorldSpaceCameraPos - vert.positionWS);
    surface.depth = -TransformWorldToView(vert.positionWS).z;
	surface.color = texColor.rgb;
	surface.alpha = texColor.a;
    surface.metallic = GetMetallic();
    surface.smoothness = GetSmoothness();
    surface.dither = InterleavedGradientNoise(vert.positionCS.xy, 0);

	BRDF brdf = GetBRDF(surface);
//    return texColor;
    GI gi = GetGI(GI_FRAGMENT_DATA(vert), surface);
    return float4(GetLighting(surface, brdf, gi), surface.alpha);
}

#endif //MY_LEGACY_LIGHT_PASS_INCLUDE