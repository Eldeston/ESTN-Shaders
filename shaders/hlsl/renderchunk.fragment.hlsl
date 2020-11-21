#include "ShaderConstants.fxh"
#include "util.fxh"

// Including files...
#include "assets/functionLib.fxh"

struct PS_Input
{
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
};

struct PS_Output
{
	float4 color : SV_Target;
};

//#define tTime sin(TOTAL_REAL_WORLD_TIME * .5)

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#ifdef BYPASS_PIXEL_SHADER
    PSOutput.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
    return;
#else

	#if USE_TEXEL_AA
		float4 albedo = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 );
	#else
		float4 albedo = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
	#endif

	// Get world surface normal
	float3 T = normalize(ddx(PSInput.vert_pos));
	float3 B = normalize(ddy(PSInput.vert_pos));
	float3 N = normalize(cross(T, B));


	float d0 = maxC(A_Contrast(albedo.rgb, normDetail));
	#if USE_TEXEL_AA
		float d1 = maxC(A_Contrast(texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 + float2(delta, 0)).rgb, normDetail));
		float d2 = maxC(A_Contrast(texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 + float2(0, delta)).rgb, normDetail));
	#else
		float d1 = maxC(A_Contrast(TEXTURE_0.Sample(TextureSampler0, PSInput.uv0 + float2(delta, 0)).rgb, normDetail));
		float d2 = maxC(A_Contrast(TEXTURE_0.Sample(TextureSampler0, PSInput.uv0 + float2(0, delta)).rgb, normDetail));
	#endif


	float dx = (d0 - d1) / delta;
	float dy = (d0 - d2) / delta;
	float3 normalMap = normalize(float3(dx, dy, 5. * normDetail));

	#ifdef NORMAL_MAPS
		float3x3 TBN = {T, B, N};
		TBN=transpose(TBN);
		float detailFar = min(length(PSInput.world_pos) / 16., 1.);
		//N = (normalMap * TBN) * (1. - detailFar) + N * detailFar;
		N = mul(normalMap,TBN) * (1. - detailFar) + N * detailFar;
	#endif
	
	//checkpoint

	// Main variables...
	float dayA = pow(saturate(1. - FOG_COLOR.b * 1.2), .5);
	float nightA = pow(saturate(1. - FOG_COLOR.r * 1.5),1.2);
	float rainA = saturate(pow((.7 - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 3.));

	float terrainTime = pow(maxC(TEXTURE_1.Sample(TextureSampler1, float2(0, 1))), 5.);
	float terraDim0 = maxC(TEXTURE_1.Sample(TextureSampler1, float2(0, 1)));
	float terraDim1 = maxC(TEXTURE_1.Sample(TextureSampler1, float2(0,0)));
	float lightMap = maxC(TEXTURE_1.Sample(TextureSampler1, float2(PSInput.uv1.x, 0)));
	float shdMap = maxC(TEXTURE_1.Sample(TextureSampler1, float2(0, PSInput.uv1.y)));
	float2 uv2 = saturate(pow(PSInput.uv1, float2(lightShrp, 1)) * float2(lightSize, 1));//works
	
	//checkpoint
	
	// Beam rendering goes here
	float beamFar = saturate(abs(-PSInput.world_pos.x) / (RENDER_DISTANCE / 1.6));
	float sunBeam = pow(vnoise(atan2(PSInput.world_pos.y, PSInput.world_pos.z) / (pi * 2.) * 75.1), 1.75) * 1.75;
	//note: mc's hlsl doesnt like moving float2s between verted and fragment...
	sunBeam = smoothstep(1.0, 0.2, length(PSInput.screenPos.xy * PSInput.screenPos.xy * PSInput.screenPos.xy)) * lerp(saturate(sunBeam) * smoothstep(0.2, 1.0, length(PSInput.world_pos.yz) / 16.0), 1.0, saturate(beamFar * beamFar * beamFar));
	
	//checkpoint
	
	#ifdef SEASONS_FAR
		albedo.a = 1.;
	#endif

	#if USE_ALPHA_TEST
		#ifdef ALPHA_TO_COVERAGE
		#define ALPHA_THRESHOLD .05
		#else
		#define ALPHA_THRESHOLD .5
		#endif
		if(albedo.a < ALPHA_THRESHOLD)
			discard;
	#endif
		
	float4 inColor = PSInput.color;

	#if defined(BLEND)
		albedo.a *= inColor.a;
	#endif

	#if !defined(ALWAYS_LIT)
		float emissive = smoothstep(.864, 1., saturate(lerp(.45, maxC(albedo), 2.5))) * maxC(albedo);
		albedo *= TEXTURE_1.Sample(TextureSampler1, uv2);
		#ifdef EMISSIVE_MAPS
			albedo.rgb *= isBlock(PSInput.color) ? lerp(1., emissValue * lerp(.4, 1., emissive), smoothstep(.8564, .8745, PSInput.uv1.x) * lerp(1. - shdMap * shdMap * shdMap * shdMap * shdMap, lerp(1., .4, PSInput.uv1.y), rainA)) : 1.;
		#endif
	#endif

	#ifndef SEASONS
		#if !USE_ALPHA_TEST && !defined(BLEND)
			albedo.a = inColor.a;
		#endif
		
		float4 hsvCol = rgb2hsv(inColor);
		float colAmb = normalize(float2(hsvCol.z, .56)).x;
		inColor.rgb = isBlock(PSInput.color) ? sqrt(PSInput.color.rgb) : hsv2rgb(float4(hsvCol.xy, colAmb, 1.)).rgb;
		albedo.rgb *= inColor.rgb;
	#else
		float2 uv = inColor.xy;
		albedo.rgb *= lerp(float3(1,1,1), TEXTURE_2.Sample(TextureSampler2, uv).rgb * 2., inColor.b);
		albedo.rgb *= inColor.aaa;
		albedo.a = 1.;
	#endif
	
	//checkpoint
	
	float3 shadowAmbient = shadowCol * shadow_B * lerp(albedo.rgb, float3(1,1,1), PSInput.fog_vals.x);

	// Calculate the shadows
	float shdX =0;
	float shdY = 0;
	#ifdef NORM_SHADOWS
		//shdX = max(N.y, N.z) < .5 && !(saturate(abs(N.z)) > .75) ? 1. : 0.;//wrong direction, will have upside down lighting if extra shadows off
		shdX = max(N.y, N.z) < .5 && !(saturate(abs(N.z)) > .75) ? 0. : 1.;
	#endif
	#ifdef EXTRA_SHADOWS
		shdX = isBlock(PSInput.color) ? 1. - (maxC(PSInput.color) - .64) * 31. : shdX;
	#endif
	#ifdef BASIC_SHADOWS
		shdY = 1. - (PSInput.uv1.y - .867) * 124.;
	#endif
	float shadow_v = saturate(max(shdX, shdY)) * shdAlpha;

	#ifdef SHADOW_FOG
		shadow_v = saturate(lerp(shadow_v, shadow_v * 1.4, PSInput.fog_vals.x));
	#endif

	albedo.rgb = lerp(albedo.rgb, shadowAmbient, shadow_v * (1. - uv2.x) * pow(lerp(1., shdAlpha, max(dayA, rainA)), 1.4));
	
	//checkpoint
	
	#if (!defined(ALPHA_TEST) && defined(WATER_NOISE)) || (defined(UNDERWATER) && defined(UNDERWATER_CAUSTIC))
		#if NOISE_T
			float waterNoi = voronoi2D(frac(PSInput.vert_pos.xz / 16.), TOTAL_REAL_WORLD_TIME * .27, 3.);
		#else
			float waterNoi = vnoise(frac(PSInput.vert_pos.xz / 16.), TOTAL_REAL_WORLD_TIME * .08, 6.) * .9;
		#endif
		#ifdef LAYERED_NOISE
			waterNoi += vnoise(frac(PSInput.vert_pos.xz / 16.), TOTAL_REAL_WORLD_TIME * .2, 45.) * .15;
		#endif
	#endif

	#if !defined(ALPHA_TEST) && defined(WATER_NOISE) // Water noise applied
		albedo.rgb *= PSInput.originAlpha < .95 && PSInput.originAlpha != 0. && !(isBlock(PSInput.color)) ? saturate(((waterNoi * waterNoi * waterNoi * waterNoi * 1.2) + .36) * (1. - PSInput.fog_vals.z) + PSInput.fog_vals.z) : 1.;
	#endif

	#if defined(UNDERWATER) && defined(UNDERWATER_CAUSTIC) // Water caustics applied
		float causticNoi = saturate((waterNoi * waterNoi * waterNoi * waterNoi * 1.8) + .32);
		albedo.rgb *= lerp(lerp(causticNoi, 1., PSInput.uv1.y * 1.24), lerp(lerp(causticNoi, 1., .75), 1., PSInput.uv1.y * 1.24), PSInput.uv1.x);
		albedo.rgb *= lerp(max(FOG_COLOR.rgb, hsv2rgb(float4(rgb2hsv(FOG_COLOR).x, .75, 1, 1)).rgb), float3(1,1,1), max(PSInput.uv1.x, PSInput.uv1.y));
	#endif

	#ifndef UNDERWATER // Light applied before tonemap, only if it's not underwater
		albedo.rgb = lerp(albedo.rgb + (lightCol * uv2.x), albedo.rgb, lerp(shdMap, .5, rainA));
	#endif

	albedo.rgb = toneA(albedo.rgb);
	
	//checkpoint
	
	// Mono buffer applied after tonemap
	float3 grey_s = A_Saturation(albedo.rgb, lerp(monoSat, 1., uv2.x));

	#ifndef UNDERWATER // The monochromatic effect will render differently for terrain, if the player is not underwater
		float rainExp = rainA * uv2.y;
		albedo.rgb = FOG_CONTROL.x < 1. && FOG_CONTROL.x > 0. ? lerp(albedo.rgb, grey_s * lerp(mono_B, 1., uv2.x), rainExp) : albedo.rgb;
	#endif

	#ifdef CUSTOM_ANGLE
		#define ANGLE (customAngle / 360.) * pi
	#else
		#define ANGLE (terrainTime - .5) * pi
	#endif


	float2x2 rotMat = ROT2D(ANGLE);
	float3 lPos = normalize(float3(mul(float2(100, 0), rotMat), 0) + PSInput.world_pos);
	float3 rPos = reflect(-lPos, N);
	float spec = max(dot(rPos, normalize(-PSInput.world_pos)), 0.);
	#if USE_TEXEL_AA
		float3 baseSpec = isBlock(PSInput.color) ? A_Saturation(texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0).rgb, .6) : texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0).rgb * A_Saturation(inColor.rgb, .5);
	#else
		float3 baseSpec = isBlock(PSInput.color) ? A_Saturation(TEXTURE_0.Sample(TextureSampler0, PSInput.uv0).rgb, .6) : TEXTURE_0.Sample(TextureSampler0, PSInput.uv0).rgb * A_Saturation(inColor.rgb, .5);
	#endif
	
	//checkpoint
	
	#if !defined(ALPHA_TEST) && defined(SPECULAR)
		albedo += pow(spec, 16.) * sqrt(rgb2hsv(float4(baseSpec, 1)).y * 1.3) * lerp(lerp(lerp(sld_color, sls_color, dayA), sln_color, nightA), float4(0,0,0,0), rainA) * (1. - saturate(max(shdX, shdY)));
	#endif

	#ifdef HDR // HDR applied
		albedo = rgb2hdr(albedo);
	#endif

	//checkpoint
	
	#ifdef ATMO // Atmospheric fog takes place here
		float3 atmoCol = isDimen(terraDim0, terraDim1) ? FOG_COLOR.rgb * 2. : lerp(lerp(lerp(ad_color, as_color, dayA), an_color, nightA), lerp(float4(0.24,0.24,0.24,0.24), FOG_COLOR, maxC(FOG_COLOR)), rainA).rgb;
		albedo.rgb = lerp(albedo.rgb, atmoCol, PSInput.fog_vals.z);
	#endif

	#ifdef BEAMS // Sunbeams are applied after atmospheric fog
		albedo.rgb = isDimen(terraDim0, terraDim1) ? albedo.rgb : lerp(albedo.rgb, A_Saturation(FOG_COLOR.rgb * 1.6, 1.2)* sunBeam, saturate(PSInput.fog_vals.y * PSInput.uv1.y));
	
	#endif

	//checkpoint
	
	#ifdef DEBUG
		albedo = float4(floor(PSInput.vert_pos) / 16., 1);
		albedo.rgb = lerp(lerp(albedo.rgb, float3(0, 0, 1), PSInput.fog_vals.z * 1.16), float3(1, 1, 0), PSInput.fog_vals.y * 1.44);
	#endif

	#ifdef FOG // Default fog applied after all the applied effects
		albedo.rgb = lerp(albedo.rgb, isDimen(terraDim0, terraDim1) ? FOG_COLOR.rgb : PSInput.fogColor.rgb, PSInput.fogColor.a);
	#endif

	PSOutput.color = albedo;
	
	#ifdef VR_MODE
		// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to 
		// the lowest 8 bit value.
		PSOutput.color = max(PSOutput.color, 1 / 255.0f);
	#endif

#endif // BYPASS_PIXEL_SHADER
}