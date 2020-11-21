#include "ShaderConstants.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct VS_Input
{
    float3 position : POSITION;
    float2 uv : TEXCOORD_0;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input
{
    float4 position : SV_Position;
	float3 cube_pos : CUBEPOS;
    float2 uv : TEXCOORD_0;
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
    PSInput.uv = VSInput.uv;
	
	PSInput.cube_pos =  VSInput.position;
	float4 N = float4( VSInput.position, 1 );
	
	#ifdef CCUBEMAP_SHADER
		float gradient = length(N.xz);
		N.y -= VSInput.position.y > 0. ? gradient * .45 : -.32;
	#endif
	
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], N );
	#else
		PSInput.position = mul(WORLDVIEWPROJ, N );
	#endif
	#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
	#endif 
	#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
	#endif
}