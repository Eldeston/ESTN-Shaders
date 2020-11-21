// --------------- Code Library ---------------- //
// All main codes will be gathered here in this file

#include "assets/convertWin10.fr"

#include "assets/presetDefinitions.fr"

// replaced clamp2 => saturate()
// float clamp2(float x){ return min(max(x, 0.), 1.); }
// float2 clamp2(float2 x){ return min(max(x, float2(0,0)), float2(1,1)); }
// float3 clamp2(float3 x){ return min(max(x, float3(0,0)), float3(1,1)); }
float maxC(float3 x) { return max(x.r, max(x.g, x.b)); }
float maxC(float4 x) { return max(x.r, max(x.g, x.b)); }

float3 A_Saturation(float3 col, float a){
	// Algorithm from Chapter 16 of OpenGL Shading Language
	return (col.r * .2125 + col.g * .7154 + col.b * .0721) * (1. - a) + col * a;
	}

float3 A_Exposure(float3 col, float amount){
	return saturate(col + (amount - 1.));
	}

float3 A_Contrast(float3 col, float a){
	return saturate(.5 * (1. - a) + col.rgb * a);
	}

float3 toneA(float3 base){
	return A_Exposure(A_Contrast(A_Saturation(base.rgb, saturation), contrast), exposure) * brightness;
	}

// Biome/Environment detectors, these determine certain conditions
// according to the environmental changes around the player

// Color picker using an rgb2hsv converter, used to select multiple colors
// and compare it with another color, this is needed for color-accurate
// info on the biome environment. Taken from:
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float4 rgb2hsv(float4 c){
	float4 K = float4(0, -1. / 3., 2. / 3., -1);
	float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
	float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1e-10;
	return float4(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x, c.a);
	}

// For converting hsv to rgb
float4 hsv2rgb(float4 c){
	float4 K = float4(1, 2. / 3., 1. / 3., 3);
	float3 p = abs(frac(c.xxx + K.xyz) * 6. - K.www);
	return float4(c.z * lerp(K.xxx, clamp(p - K.xxx, 0., 1.), c.y), c.a);
	}

// Using hsv is such a blessing since I can finally fix previous bugs that
// have been long left alone in previous versions (except alpha)
bool isWater(float4 col){
    float4 hsv = rgb2hsv(col);
    return hsv.x >= .397 && hsv.x <= .722;
	}

bool isSwamp(float4 col){
	float4 hsv = rgb2hsv(col);
	return hsv.x >= .184 && hsv.x <= .234 && hsv.z <= .441;
	}

// In color, the blocks that AREN'T affected by biome colors are by
// default white, this is good info since it stays white
bool isBlock(float4 col){
	return rgb2hsv(col).y == 0.;
	}

bool isPlant(float4 col){
    float4 hsv = rgb2hsv(col);
    return hsv.x >= 0.15 && hsv.x <= 0.4;
	}

// Detects if the player is in another dimension by using TEXTURE_0 since it contains that specific info...
bool isDimen(float col0, float col1){
    return col0 == col1;
	}

float4 rgb2hdr(float4 col){
	return float4(col.rgb * SV * (1. - col.rgb) + col.rgb * HV * col.rgb, col.a);
	}

// Other functions and helpful variables
// float pi = 4. * atan(1.);
#define pi 4 * atan(1.)
#define MIX2(x, y, z, w) w < .5 ? lerp(x, y, saturate((w) / .5)) : lerp(y, z, saturate(((w) - .5) / .5))
#define GENWAVES(x, y, z) (sin(dot(x, y)) * z)
#define GENWAVEC(x, y, z) (cos(dot(x, y)) * z)
//#define ROT2D(x) float2x2(cos(x),-sin(x), sin(x),cos(x))
#define ROT2D(x) {cos(x),-sin(x), sin(x),cos(x)}

// Noise functions, all the values are hardcoded to , don't change precisions
// Seeds, (adjust it if you like)
 //float4 s0 = float4(12.9898, 4.1414, 78.233, 314.13);
#define s0 float4(12.9898, 4.1414, 78.233, 314.13)
// Must be 1 integer apart ex. 0.36, 1.36, 2.36.....
 //float4 s1 = float4(.1031, 1.1031, 2.1031, 3.1031);
#define s1 float4(.1031, 1.1031, 2.1031, 3.1031)

// Noise functions
// 1 out, 2 in...
float rand12( float2 n){
	return frac(sin(dot(n, s0.xy)) * 10000);
	}

// 2 out, 2 in...
float2 rand22( float2 n){
	return frac(sin(float2(dot(n, s0.xy), dot(n, s0.zw))) * 10000);
	}

// 3 out, 2 in...
float3 rand32( float2 n){
	return frac(sin(float3(dot(n, s0.xy), dot(n, s0.yz), dot(n, s0.zw))) * 10000);
	}
	
// 3 out, 3 in...
float3 rand33( float3 n){
	return frac(sin(float3(dot(n, s0.xyz), dot(n, s0.yzw), dot(n, s0.zwx))) * 10000);
	}

// Random noise alternatives with a larger range but more performance heavy
// 1 out, 1 in...
float hash11( float p){
	 float p1 = frac(p * s1.x);
	p1 *= p1 + 33.33;
	return frac(p1 * p1 * 2.);
	}

// Modified value noise for the beams
float vnoise( float p){
	 float i = floor(p); float f = frac(p);
	return lerp(hash11(i), hash11(i + 1.), f * f * f * (f * (f * 6. - 15.) + 10.));
	}

float vnoise( float2 p,  float time,  float tiles){
	p = p * tiles + time;
	float2 i = floor(p); float2 f = frac(p);
	float2 u = f * f * f * (f * (f * 6. - 15.) + 10.);
	return lerp(lerp(rand12(fmod(i, tiles)), rand12(fmod(i + float2(1, 0), tiles)), u.x), lerp(rand12(fmod(i + float2(0, 1), tiles)), rand12(fmod(i + 1., tiles)), u.x), u.y);
	}

// Voronoi
float voronoi2D( float2 uv,  float time,  float tiles){
	uv *= tiles; float dist = 1.;
	for(int x = 0; x <= 1; x++){
		for(int y = 0; y <= 1; y++){
			float2 p = floor(uv) + float2(x, y);
			float d = length(.27 * sin(rand22(fmod(p, tiles)) * 12. + time) + float2(x, y) - frac(uv));
			dist = min(d, dist);
			}
		}
	return dist;
	}

// Pixelate function, 2D
float2 pix2D(float2 uv, float pixSize){
	float pix = pixSize / 500.;
	float2 finalUV = pix * floor(uv / pix);
	return finalUV;
	}

// Debug functions
float plot(float2 st, float pct){
	return  smoothstep(pct - .02, pct, st.y) - smoothstep(pct, pct + .02, st.y);
	}