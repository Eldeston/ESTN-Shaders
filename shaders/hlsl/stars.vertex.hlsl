#include "ShaderConstants.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct VS_Input
{
    float3 position : POSITION;
    float4 color : COLOR;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input
{
    float4 position : SV_Position;
	float3 star_pos : STARPOS;
    float4 color : COLOR;
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
    PSInput.color = VSInput.color;
	PSInput.star_pos = VSInput.position;
#ifdef INSTANCEDSTEREO
	int i = VSInput.instanceID;
	PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], float4( VSInput.position, 1 ) );
#else
	PSInput.position = mul(WORLDVIEWPROJ, float4(VSInput.position, 1));
#endif
#ifdef GEOMETRY_INSTANCEDSTEREO
	PSInput.instanceID = VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	PSInput.renTarget_id = VSInput.instanceID;
#endif
}