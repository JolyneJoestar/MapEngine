#ifndef NPR_INCLUDE
#define NPR_INCLUDE

float4 _ColorStreet;
float _SpecularSegment;

float3 GetNPRLighting(Surface surface, BRDF brdf, Light light)
{
	float spec = SpecularStrength(surface, brdf, light);
	float diff = IncomingLightAttenua(surface, light);
	float w = fwidth(diff) * 2.0;
	if (diff < _ColorStreet.x + w)
	{
		diff = lerp(_ColorStreet.x, _ColorStreet.y, smoothstep(_ColorStreet.x - w, _ColorStreet.x + w, diff));
	}
	else if (diff < _ColorStreet.y + w)
	{
		diff = lerp(_ColorStreet.y, _ColorStreet.z, smoothstep(_ColorStreet.y - w, _ColorStreet.y + w, diff));
	}
	else if (diff < _ColorStreet.z + w)
	{
		diff = lerp(_ColorStreet.z, _ColorStreet.w, smoothstep(_ColorStreet.z - w, _ColorStreet.z + w, diff));
	}
	else
	{
		diff = _ColorStreet.w;
	}
	w = fwidth(spec);
	if (spec < _SpecularSegment + w)
	{
		spec = lerp(0, spec, smoothstep(_SpecularSegment - w, _SpecularSegment + w, spec));
	}
	else
		spec = spec;
	return diff * light.color * surface.color * (spec * 1.0 + brdf.diffuse) * light.attenuation;
}


#endif //NPR_INCLUDE