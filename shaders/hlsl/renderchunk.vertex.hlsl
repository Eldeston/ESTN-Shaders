#include "ShaderConstants.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct VS_Input {
	float3 position : POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD_0;
	float2 uv1 : TEXCOORD_1;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input {
	float4 position : SV_Position;
	float3 world_pos : WORLDPOS;
	float3 vert_pos : VERTPOS;
	float3 screenPos : SCREENPOS;
	float3 fog_vals : FOGVALS;//=[shdFog, beamFog, atmoFog]
	float originAlpha:OA;
#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float4 fogColor : FOG_COLOR;
#endif
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};


static const float rA = 1.0;
static const float rB = 1.0;
static const float3 UNIT_Y = float3(0, 1, 0);
static const float DIST_DESATURATION = 56.0 / 255.0; //WARNING this value is also hardcoded in the water color, don'tchange


ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
#ifndef BYPASS_PIXEL_SHADER
	PSInput.uv0 = VSInput.uv0;
	PSInput.uv1 = VSInput.uv1;
	PSInput.color = VSInput.color;
#endif

#ifdef AS_ENTITY_RENDERER
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul(WORLDVIEWPROJ_STEREO[i], float4(VSInput.position, 1));
	#else
		PSInput.position = mul(WORLDVIEWPROJ, float4(VSInput.position, 1));
	#endif
		float3 worldPos = PSInput.position;
#else
		float3 worldPos = (VSInput.position.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
	
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
	
		PSInput.position = mul(WORLDVIEW_STEREO[i], float4(worldPos, 1 ));
		PSInput.position = mul(PROJ_STEREO[i], PSInput.position);
	
	#else
		PSInput.position = mul(WORLDVIEW, float4( worldPos, 1 ));
		PSInput.position = mul(PROJ, PSInput.position);
	#endif

#endif
#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
#endif
///// find distance from the camera

//#if defined(FOG) || defined(BLEND)//always get distance
	#ifdef FANCY
		float3 relPos = -worldPos;
		float cameraDepth = length(relPos);
	#else
		float cameraDepth = PSInput.position.z;
	#endif
//#endif

///// Main variables...
float dayA = pow(saturate(1. - FOG_COLOR.b * 1.2), .5);
float nightA = pow(saturate(1. - FOG_COLOR.r * 1.5),1.2);
float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));
PSInput.screenPos = PSInput.position.xyz / (PSInput.position.z + 1.0);
PSInput.world_pos = worldPos.xyz;
PSInput.vert_pos = VSInput.position.xyz;
///// Method recreated, and no longer uses Genghar's way of calculating the pos
float3 tiledPos = fmod(frac(VSInput.position.xyz / 16.) * pi, pi);

///// Atmospheric fog calculation /////
float heightFog = lerp(maxHeight, minHeight, rainA);
float nightFog = lerp(densityMax, densityMin, nightA) * ((1. - rainA) + rainA * densityRain);
float height1 = worldPos.y < .0 ? -(worldPos.y / heightFog) * abs(worldPos.y / heightFog) : .0;
float height2 = worldPos.y < .0 ? -(worldPos.y / 45.) * abs(worldPos.y / 45.) : .0;
float fog1 = cameraDepth / (RENDER_DISTANCE / nightFog);
float fog2 = cameraDepth / heightFog; float fog3 = cameraDepth / 24.;
PSInput.fog_vals = float3(0,0,0);
PSInput.fog_vals.z = clamp(lerp(fog1 * fog1, sqrt(fog2), height1), .0, .7);
PSInput.fog_vals.y = clamp(lerp(fog3, sqrt(fog2), height2), .0, .64) * dayA * pow(1. - nightA, 4.);
#ifdef SHADOW_FOG
	PSInput.fog_vals.x = saturate(lerp(fog1 * fog1, sqrt(fog2), height1)) * lerp(1., .64, nightA);
//#else
	//PSInput.fog_vals.x = 0.;
#endif

///// Animated foilage, water and underwater distortion
///// Now detects if it's a foilage or water block with 90% accuracy
// First indicate the areas where it should render waves or not
float waveFar = smoothstep(36., 24., cameraDepth);
#if defined(ALPHA_TEST) && defined(PLANT_WAVES)
	float wind = GENWAVEC(float3(tiledPos.xz, TOTAL_REAL_WORLD_TIME), float3(1,1, 1.6), .75 * VSInput.uv1.y);
	PSInput.position.x += isPlant(VSInput.color) && !(isBlock(VSInput.color)) ? GENWAVES(float4(tiledPos, TOTAL_REAL_WORLD_TIME), float4(6, -6, 6, 3), .025) + lerp(.014, -.028, wind) : .0;
	// color += wind; // Visualize wind
#endif

#if defined(WATER_WAVES) && defined(BLEND)
	PSInput.position.y += VSInput.color.a < .95 && !(isBlock(VSInput.color)) ? GENWAVEC(float4(tiledPos, TOTAL_REAL_WORLD_TIME), float4(4,4,4, 3), .064 * waveFar) : .0;
#endif

#if defined(UNDERWATER_WAVES) && defined(UNDERWATER)
	PSInput.position.x += GENWAVEC(float3(PSInput.screenPos.xy, TOTAL_REAL_WORLD_TIME), float3(12, 6, 1), .016 * (PSInput.position.z + 1.));
#endif

///// apply fog

#ifdef FOG
	float len = cameraDepth / RENDER_DISTANCE;
	#ifdef ALLOW_FADE
		len += RENDER_CHUNK_FOG_ALPHA;
	#endif

    PSInput.fogColor.rgb = lerp(lerp(lerp(fd_color, fs_color, dayA), fn_color, nightA), FOG_COLOR, rainA).rgb;
	PSInput.fogColor.a = clamp((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), .0, 1.);

	// Water fog
    #ifdef UNDERWATER
       PSInput.fogColor.rgb = FOG_COLOR.rgb;
    #endif
#endif

//for water detection:
PSInput.originAlpha = VSInput.color.a;//check if <0.95

///// blended layer (mostly water) magic
#ifdef BLEND
	//Mega hack: only things that become opaque are allowed to have vertex-driven transparency in the Blended layer...
	//to fix an ion this we'd need to find more space for a flag in the vertex format. color.a is the only unused part
	bool shouldBecomeOpaqueInTheDistance = VSInput.color.a < 0.95;
	if(shouldBecomeOpaqueInTheDistance) {
		#ifdef FANCY  /////enhance water
			float cameraDist = cameraDepth / FAR_CHUNKS_DISTANCE;
		#else
			float3 relPos = -worldPos.xyz;
			float camDist = length(relPos);
			float cameraDist = camDist / FAR_CHUNKS_DISTANCE;
		#endif //FANCY
		
		float alphaFadeOut = clamp(cameraDist, 0.0, 1.0);
		PSInput.color.a = lerp(VSInput.color.a, 1.0, alphaFadeOut);
	}
#endif

}
