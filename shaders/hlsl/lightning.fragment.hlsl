#include "ShaderConstants.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct PS_Input
{
    float4 position : SV_Position;
    float4 color : COLOR;
};

struct PS_Output
{
    float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
    PSOutput.color = float4(toneA(PSInput.color.rgb),PSInput.color.a);
}