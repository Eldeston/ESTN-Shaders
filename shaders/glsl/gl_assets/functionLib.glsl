// --------------- Code Library ---------------- //
// All main codes will be gathered here in this file

#include "gl_assets/presetDefinitions.fr"

float clamp2(float x){ return min(max(x, 0.), 1.); }
vec2 clamp2(vec2 x){ return min(max(x, vec2(0)), vec2(1)); }
vec3 clamp2(vec3 x){ return min(max(x, vec3(0)), vec3(1)); }
float maxC(vec3 x) { return max(x.r, max(x.g, x.b)); }
float maxC(vec4 x) { return max(x.r, max(x.g, x.b)); }

vec3 A_Saturation(vec3 col, float a){
	// Algorithm from Chapter 16 of OpenGL Shading Language
	return (col.r * .2125 + col.g * .7154 + col.b * .0721) * (1. - a) + col * a;
	}

vec3 A_Exposure(vec3 col, float amount){
	return clamp2(col + (amount - 1.));
	}

vec3 A_Contrast(vec3 col, float a){
	return clamp2(.5 * (1. - a) + col.rgb * a);
	}

vec3 toneA(vec3 base){
	return A_Exposure(A_Contrast(A_Saturation(base.rgb, saturation), contrast), exposure) * brightness;
	}

// Biome/Environment detectors, these determine certain conditions
// according to the environmental changes around the player

// Color picker using an rgb2hsv converter, used to select multiple colors
// and compare it with another color, this is needed for color-accurate
// info on the biome environment. Taken from:
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec4 rgb2hsv(vec4 c){
	highp vec4 K = vec4(0, -1. / 3., 2. / 3., -1);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);
	float d = q.x - min(q.w, q.y);
	float e = 1e-10;
	return vec4(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x, c.a);
	}

// For converting hsv to rgb
vec4 hsv2rgb(vec4 c){
	highp vec4 K = vec4(1, 2. / 3., 1. / 3., 3);
	highp vec3 p = abs(fract(c.xxx + K.xyz) * 6. - K.www);
	return vec4(c.z * mix(K.xxx, clamp(p - K.xxx, 0., 1.), c.y), c.a);
	}

// Using hsv is such a blessing since I can finally fix previous bugs that
// have been long left alone in previous versions (except alpha)
bool isWater(vec4 col){
    vec4 hsv = rgb2hsv(col);
    return hsv.x >= .397 && hsv.x <= .722;
}

bool isSwamp(vec4 col){
	vec4 hsv = rgb2hsv(col);
	return hsv.x >= .184 && hsv.x <= .234 && hsv.z <= .441;
	}

// In color, the blocks that AREN'T affected by biome colors are by
// default white, this is good info since it stays white
bool isBlock(vec4 col){
	return rgb2hsv(col).y == 0.;
	}

bool isPlant(vec4 col){
    vec4 hsv = rgb2hsv(col);
    return hsv.x >= 0.15 && hsv.x <= 0.4;
	}

// Detects if the player is in another dimension by using TEXTURE_0 since it contains that specific info...
bool isDimen(float col0, float col1){
    return col0 == col1;
	}

vec4 rgb2hdr(vec4 col){
	return vec4(col.rgb * SV * (1. - col.rgb) + col.rgb * HV * col.rgb, col.a);
	}

// Other functions and helpful variables
highp float pi = 4. * atan(1.);
#define MIX2(x, y, z, w) w < .5 ? mix(x, y, clamp2((w) / .5)) : mix(y, z, clamp2(((w) - .5) / .5))
#define GENWAVES(x, y, z) (sin(dot(x, y)) * z)
#define GENWAVEC(x, y, z) (cos(dot(x, y)) * z)
#define ROT2D(x) mat2(cos(x),-sin(x), sin(x),cos(x))

// Noise functions, all the values are hardcoded to highp, don't change precisions
// Seeds, (adjust it if you like)
highp vec4 s0 = vec4(12.9898, 4.1414, 78.233, 314.13);
// Must be 1 integer apart ex. 0.36, 1.36, 2.36.....
highp vec4 s1 = vec4(.1031, 1.1031, 2.1031, 3.1031);

// Noise functions
// 1 out, 2 in...
float rand12(highp vec2 n){
	return fract(sin(dot(n, s0.xy)) * 1e4);
	}

// 2 out, 2 in...
vec2 rand22(highp vec2 n){
	return fract(sin(vec2(dot(n, s0.xy), dot(n, s0.zw))) * 1e4);
	}

// 3 out, 2 in...
vec3 rand32(highp vec2 n){
	return fract(sin(vec3(dot(n, s0.xy), dot(n, s0.yz), dot(n, s0.zw))) * 1e4);
	}
	
// 3 out, 3 in...
vec3 rand33(highp vec3 n){
	return fract(sin(vec3(dot(n, s0.xyz), dot(n, s0.yzw), dot(n, s0.zwx))) * 1e4);
	}

// Random noise alternatives with a larger range but more performance heavy
// 1 out, 1 in...
float hash11(highp float p){
	highp float p1 = fract(p * s1.x);
	p1 *= p1 + 33.33;
	return fract(p1 * p1 * 2.);
	}

// Modified value noise for the beams
float vnoise(highp float p){
	highp float i = floor(p); float f = fract(p);
	return mix(hash11(i), hash11(i + 1.), f * f * f * (f * (f * 6. - 15.) + 10.));
	}

float vnoise(highp vec2 p, highp float time, highp float tiles){
	p = p * tiles + time;
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6. - 15.) + 10.);
	return mix(mix(rand12(mod(i, tiles)), rand12(mod(i + vec2(1, 0), tiles)), u.x), mix(rand12(mod(i + vec2(0, 1), tiles)), rand12(mod(i + 1., tiles)), u.x), u.y);
	}

// Voronoi
float voronoi2D(highp vec2 uv, highp float time, highp float tiles){
	uv *= tiles; float dist = 1.;
	for(int x = 0; x <= 1; x++){
		for(int y = 0; y <= 1; y++){
			vec2 p = floor(uv) + vec2(x, y);
			float d = length(.27 * sin(rand22(mod(p, tiles)) * 12. + time) + vec2(x, y) - fract(uv));
			dist = min(d, dist);
			}
		}
	return dist;
	}

// Pixelate function, 2D
vec2 pix2D(vec2 uv, float pixSize){
	float pix = pixSize / 500.;
	vec2 finalUV = pix * floor(uv / pix);
	return finalUV;
	}

// Debug functions
float plot(vec2 st, float pct){
	return  smoothstep(pct - .02, pct, st.y) - smoothstep(pct, pct + .02, st.y);
	}