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
	float2 sun_pos : SUNPOS;
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
	PSInput.sun_pos=VSInput.position.xz;
	#ifdef CSUN
		float3 N = VSInput.position* float3(12, .25, 12);
		N.y -= .32;
	#else
		float3 N = VSInput.position;
	#endif
	
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], float4( N, 1 ) );
	#else
		PSInput.position = mul(WORLDVIEWPROJ, float4(N, 1));
	#endif
	#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
	#endif 
	#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
	#endif
}