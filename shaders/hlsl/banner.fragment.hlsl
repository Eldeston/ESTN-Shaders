#include "ShaderConstants.fxh"
#include "Util.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct PS_Input {
	float4 position : SV_Position;
#ifdef ENABLE_LIGHT
	float4 light : LIGHT;
#endif
#ifdef ENABLE_FOG
	float4 fogColor : FOG_COLOR;
#endif

#ifndef DISABLE_TINTING
	float4 color : COLOR;
#endif

	float4 texCoords : TEXCOORD_0_FB_MSAA;
};

struct PS_Output
{
	float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.texCoords.xy);
	float4 base = TEXTURE_0.Sample(TextureSampler0, PSInput.texCoords.zw);

	#ifndef DISABLE_TINTING
		base.a = lerp(diffuse.r * diffuse.a, diffuse.a, PSInput.color.a);
		base.rgb *= PSInput.color.rgb;
	#endif

	// Main variables....
	float dayA = pow(saturate(1. - FOG_COLOR.b * 1.2), .5);
	float nightA = pow(saturate(1. - FOG_COLOR.r * 1.5), 1.2);
	float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));

	float3 shadowAmbient = shadowCol * shadow_B * base.rgb;

	//#ifdef ENABLE_LIGHT
		//base.rgb *= PSInput.light.rgb;
	//#endif

	#ifdef ENABLE_LIGHT
		float uv1x = maxC(PSInput.light);
		float uv2x = saturate(pow(uv1x, lightShrp) * lightSize);
		float shadow_v = shdAlpha * 1.2 * (1. - uv2x) * lerp(1., .64, max(nightA, rainA));
		base.rgb *= sqrt(PSInput.light.rgb);
		base.rgb = base.rgb * (1. - shadow_v) + shadowAmbient * shadow_v;
	#else
		float uv1x = 1.;
		float uv2x = 1.;
	#endif

	#if defined(UNDERWATER) && defined(UNDERWATER_CAUSTIC)
		base.rgb *= FOG_COLOR.rgb * (1. - uv2x) + uv2x;
	#endif

	base.rgb = toneA(base.rgb);
	float3 grey_s = A_Saturation(base.rgb, monoSatE * (1. - uv2x) + uv2x);

	#ifndef UNDERWATER // The monochromatic effect will render differently for terrain, if the player is not underwater
		base.rgb = FOG_CONTROL.x < 1. && FOG_CONTROL.x > 0. ? base.rgb * (1. - rainA) + grey_s * lerp(mono_B, 1., uv2x) * rainA : base.rgb;
	#endif

	#ifdef HDR
		base = rgb2hdr(base);
	#endif

	#ifdef ENABLE_FOG
		//apply fog
		base.rgb = lerp(base.rgb, PSInput.fogColor.rgb, PSInput.fogColor.a );
	#endif

		//WARNING do not refactor this 
		PSOutput.color = base;
	#ifdef UI_ENTITY
		PSOutput.color.a *= HUD_OPACITY;
	#endif

	#ifdef VR_FEATURE
		// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to 
		// the lowest 8 bit value.
		PSOutput.color = max(PSOutput.color, 1 / 255.0f);
	#endif
}