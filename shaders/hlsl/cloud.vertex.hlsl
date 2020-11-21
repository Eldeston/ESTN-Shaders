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

static const float fogNear = 0.9;

static const float3 inverseLightDirection = float3( 0.62, 0.78, 0.0 );
static const float ambient = 0.7;

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{

	float Value = pow(saturate(maxC(CURRENT_COLOR) * 1.2), 1.2);
	Value = saturate((Value - .35) / (1. - .35));
	float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));

	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul( WORLDVIEWPROJ_STEREO[i], float4( VSInput.position, 1 ) );
		float3 worldPos = mul(WORLD_STEREO, float4(VSInput.position, 1));
	#else
		PSInput.position = mul(WORLDVIEWPROJ, float4(VSInput.position, 1));
		float3 worldPos = mul(WORLD, float4(VSInput.position, 1));
	#endif
	#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
	#endif 
	#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
	#endif
	
	float depth = length(worldPos) / RENDER_DISTANCE;
    float fog = max( depth - fogNear, 0.0 );
	
	float gradient = saturate(VSInput.position.y);
	PSInput.color = float4(float3(1,1,1), VSInput.color.a);
	#ifdef CCLOUDS
		PSInput.color.a *= lerp(gradientA1, gradientA2, gradient);
		PSInput.color.rgb *= lerp(gradientB1, gradientB2, gradient);
		PSInput.color *= lerp(MIX2(cn_color, cs_color, cd_color, Value), FOG_COLOR + float4(.12,.12,.12, 0), rainA);
	#else
		PSInput.color *= lerp(MIX2(cn_color, cs_color, cd_color, Value), FOG_COLOR + float4(.12,.12.12, 0), rainA);
	#endif
	
    PSInput.color.a *= 1.0 - fog;
	
	
}