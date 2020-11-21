#include "ShaderConstants.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct PS_Input
{
    float4 position : SV_Position;
	float3 star_pos : STARPOS;
    float4 color : COLOR;
};

struct PS_Output
{
    float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
	#ifdef CSTAR
		float twinkle = GENWAVEC(float4(PSInput.star_pos, TOTAL_REAL_WORLD_TIME), float4(1, 2, 1, starS), starB);
		PSOutput.color = float4(rand33(floor(PSInput.star_pos)) * twinkle, twinkle);

	#else
		PSOutput.color = PSInput.color;
		PSOutput.color.rgb *= CURRENT_COLOR.rgb * PSInput.color.a;
	#endif

}