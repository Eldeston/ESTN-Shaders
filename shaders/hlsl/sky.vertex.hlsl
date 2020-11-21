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

	float4 hsv = rgb2hsv(CURRENT_COLOR);
	float Value = saturate((hsv.z - .1) / (1. - .1));
	float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));

	float4 sphere = float4( VSInput.position, 1 );
    float gradient = length(sphere.xz);
	sphere.y -= gradient * lerp(skyMax, skyMin, MIX2(0., 1., 0., hsv.z));

	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], sphere );
	#else
		PSInput.position = mul(WORLDVIEWPROJ, sphere );
	#endif
	#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
	#endif 
	#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
	#endif
    //PSInput.color = lerp( CURRENT_COLOR, FOG_COLOR, VSInput.color.r );
	float4 sky = lerp(MIX2(n_color, s_color, d_color, Value), FOG_COLOR, rainA);
    
    #ifdef UNDERWATER
    	PSInput.color = FOG_COLOR;
	#else
		PSInput.color = MIX2(sky, float4(FOG_COLOR.rgb * 1.8, 1), FOG_COLOR, gradient);
	#endif

}