#include "ShaderConstants.fxh"

struct PS_Input
{
	float4 position : SV_Position;
};

struct PS_Output
{
	float4 color : SV_Target;

#ifdef FORCE_DEPTH_ZERO
	float depth : SV_Depth;
#endif

};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
	//PSOutput.color = CURRENT_COLOR;
	PSOutput.color = float4(1,1,1,1);

#ifdef FORCE_DEPTH_ZERO
	PSOutput.depth = 0.0;
#endif
}