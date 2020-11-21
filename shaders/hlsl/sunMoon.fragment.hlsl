#include "ShaderConstants.fxh"
#include "util.fxh"

// Including files...
#include "assets/functionLib.fxh"


struct PS_Input
{
    float4 position : SV_Position;
	float2 sun_pos : SUNPOS;
    float2 uv : TEXCOORD_0_FB_MSAA;
};

struct PS_Output
{
    float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
	#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE) || (VERSION < 0xa000 /*D3D_FEATURE_LEVEL_10_0*/) 
		float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.uv);
	#else
		float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv);
	#endif

	#ifdef ALPHA_TEST
		if( diffuse.a < 0.5 )
		{
			discard;
		}
	#endif
	
	#ifdef CSUN
		
		float dayA = pow(saturate(1 - FOG_COLOR.b * 1.2), .5);
		float nightA = pow(saturate(1 - FOG_COLOR.r * 1.5),1.2);

		float sunRange = smoothstep(0.64, -0.24, length(PSInput.sun_pos));
		float3 sunCol = lerp(lerp(sd_color, ss_color, dayA), sn_color, nightA).rgb;

		float S = 1 - length(pow(PSInput.sun_pos / lerp(sizeSun/1000, sizeMoon/1000, nightA), sunPow));
		S = pow(saturate(S * 1.8), 1.8);
		float3 ssCol = lerp(sunCol * 2, float3(1,1,1), S);
		float4 newCol = float4(lerp(sunCol * sunRange, ssCol, S), lerp(sunRange, S, S));
		
		PSOutput.color = CURRENT_COLOR * newCol;
		
	#else
	
		#ifdef IGNORE_CURRENTCOLOR
			PSOutput.color = diffuse;
		#else
			PSOutput.color = CURRENT_COLOR * diffuse;
		#endif

	#endif

	#ifdef WINDOWSMR_MAGICALPHA
		// Set the magic MR value alpha value so that this content pops over layers
		PSOutput.color.a = 133.0f / 255.0f;
	#endif
}
