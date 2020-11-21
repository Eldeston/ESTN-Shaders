#include "ShaderConstants.fxh"
#include "util.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct PS_Input
{
    float4 position : SV_Position;
	float3 cube_pos : CUBEPOS;
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

#ifdef CCUBEMAP_SHADER 

	float Value = maxC(CURRENT_COLOR);
	Value = sqrt(saturate((Value - .2) / (1. - .2)));

	float dayA = pow(saturate(1. - FOG_COLOR.b * 1.2), .5);
	float nightA = pow(saturate(1. - FOG_COLOR.r * 1.5),1.2);
	float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));

	#ifndef UNDERWATER
		#if defined(CCLOUDS) && defined(DCLOUDS)
			int stepCount = 4;
			float2 texPos = frac(PSInput.cube_pos.xz * .12 - fmod(TOTAL_REAL_WORLD_TIME * .00025,  1.));
			
			#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE) || (VERSION < 0xa000 /*D3D_FEATURE_LEVEL_10_0*/) 
				float4 cloudTex = TEXTURE_0.Sample(TextureSampler0, texPos);
			#else
				float4 cloudTex = texture2D_AA(TEXTURE_0, TextureSampler0, texPos);
			#endif
			
			for(int n = 0; n <= stepCount; n++){
				float2 uvOffset = maxC(cloudTex) * normalize(PSInput.cube_pos).xz * .0005 * float(n);
				
				#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE) || (VERSION < 0xa000 /*D3D_FEATURE_LEVEL_10_0*/) 
					float4 texCloud3D = TEXTURE_0.Sample(TextureSampler0, texPos + uvOffset);
				#else
					float4 texCloud3D = texture2D_AA(TEXTURE_0, TextureSampler0, texPos + uvOffset);
				#endif
				
				
				if(texCloud3D.r > cloudTex.r && texCloud3D.a > 0.){
					cloudTex = float4(texCloud3D.rgb * lerp(gradientB1, gradientB2, float(n) / float(stepCount)), texCloud3D.a);
					break; //if brighter, dont need to go deeper
					}
				}
			float4 cloudCol = lerp(MIX2(cn_color, cs_color, cd_color, Value), FOG_COLOR + float4(.12,.12,.12, 0), rainA);
		#else
			float4 cloudCol = float4(0,0,0,0);
			float4 cloudTex = float4(0,0,0,0);
		#endif
		float gradient0 = smoothstep(.52, .13, length(PSInput.cube_pos.xz));
		float gradient1 = smoothstep(.52, .39, length(PSInput.cube_pos.xz));
	    float4 final = lerp(lerp(lerp(fd_color, fs_color, dayA), fn_color, nightA), FOG_COLOR, rainA);
		final.a = PSInput.cube_pos.y > 0. ? gradient0 : gradient1 * cloudTex.a;
		final.rgb = PSInput.cube_pos.y > 0. ? final.rgb : cloudCol.rgb * cloudTex.rgb;
	#else
    	final = FOG_COLOR;
	#endif
	
	PSOutput.color = final;
	
#else
	//vanilla cubemap
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
