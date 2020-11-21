/* Welcome to the Preset Dashboard 6.0! Here is where you can make changes
to the shader pack's settings!
There should be document included within this pack which shows some information and instructions.
The variables here should be understandable here so you won't get confused*/

/* Here are the togglable pack settings, disable any of these features if your phone can't handle the computation
You can disable any of these features by typing "//" next to the feature to turn it off (ex. // #define <FEATURE>) */
// Animation settings, turn it off if it's laggy
#define PLANT_WAVES
#define WATER_WAVES
// Underwater distortion
//#define UNDERWATER_WAVES

// Basic shadows
#define BASIC_SHADOWS
// World normal shadows
#define NORM_SHADOWS
// Extra shadows, disable if you don't like it
#define EXTRA_SHADOWS
// HDR Tonemapping
#define HDR

// Noise type, switch to 0 for cheap noise, and 1 for the laggy voronoi
#define NOISE_T 1 // DO NOT DISABLE BY "//"
// Layered noise, disable if laggy
#define LAYERED_NOISE
// Water noise toggle, turn this off if it's too laggy
#define WATER_NOISE
// Underwater caustic noise
#define UNDERWATER_CAUSTIC

// Atmospheric fog
#define ATMO
// Shadow fog
#define SHADOW_FOG

// If this is on, this enables cubemap manipulation to expand the sky color more.
// Turn this off if you want to apply your own cubemap texture.
#define CCUBEMAP_SHADER
// Custom sun shader
#define CSUN
// Custom stars shader
#define CSTAR
// Custom sky shader
#define CCLOUDS
// Double clouds using cubemaps (CCLOUDS MUST BE ON!)
#define DCLOUDS

// Experimental sun beams
#define BEAMS
// Experimental specular
//#define SPECULAR
// Enable if you want the light to be on a fixed angle
 //#define CUSTOM_ANGLE
// Experimental emissive maps
#define EMISSIVE_MAPS
// Experimental bump maps / normal maps, if NORM_SHADOWS is enabled, works best if EXTRA_SHADOWS is disabled
 //#define NORMAL_MAPS

// Increase if you want it more squarish, set it to 1 to make it more roundish
#define sunPow 3
// Sun size
#define sizeSun 18.0
// Moon size
#define sizeMoon 30.0
// Star brightness
#define starB 3.0
// Star twinkle speed
#define starS 0.75

// Normal map bevel, tweak it by lowering the value further or disable it if it doesn't look right
#define delta 0.000016
// Normal map detail level, keep it low as it is too strong
#define normDetail 0.005

// Default light color (The values here are low because adding color tint to lightes looks weird, but you can change it)
#define lightCol float3(0.15, 0.1, 0.05)

// The angle of the light in a fixed position in degrees, if CUSTOM_ANGLE is on
#define customAngle 180.0

// Emissive brightness of anything that emits light
#define emissValue 1.64

// Shadow color
#define shadowCol float3(0.0, 0.0, 0.64)
// Shadow brightness
#define shadow_B 0.42
// Shadow alpha or opacity
#define shdAlpha 0.64
// Sharpness of the light, the bigger the more the light gets concentrated in one place
#define lightShrp 3.0
// Size of the light, the bigger the brighter
#define lightSize 1.25

// Tonemap settings, anything higher than 2.0 means you're crazy enough to destroy your phone :D
#define saturation 1.3
#define brightness 1.2
#define exposure 1.0
#define contrast 1.08

// Rain saturation amount when it rains, 1.0 gives full saturation
#define monoSat 0.6
// Entity saturation amount when it rains
#define monoSatE 1.0
// Rain brightness
#define mono_B 0.56

// The amount of exposure in dark areas, only if HDR is defined
#define SV 1.36
// The amount of exposure in lit areas, only if HDR is defined
#define HV 1.0

/* Atmofog settings */
// Input here where should the fog appear according to height
#define maxHeight 64.0
// When it rains, this is the minimum height it will use
#define minHeight 32.0
// Maximum density multiplier when it's day
#define densityMax 1.3
// Minimum fog density multiplier when it's night
#define densityMin 1.2
// Fog density multiplier when it rains
#define densityRain 2.0

// Change sky color here
#define d_color float4(0.21, 0.7, 1., 1.0) //
#define n_color float4(0.0, 0.1, 0.2, 1.0) //
#define s_color float4(0.375, 0.125, 0.75, 1.0) //

// Change cloud color here
#define cd_color float4(1.0, 1.2, 1.2, 1.0) //
#define cn_color float4(0.0, 0.15, 0.3, 1.0) //
#define cs_color float4(0.75, 0.5, 1., 1.0) //

// Change terrain fog color here
#define fd_color float4(0.2, 0.69, 1., 1.0) //
#define fn_color float4(0.0, 0.1, 0.2, 1.0) //
#define fs_color float4(0.8, 0.4, 0.1, 1.0) //
 
// Atmospheric fog color here
#define ad_color float4(0.6, 0.8, 1.2, 1.0) //
#define an_color float4(0.16, 0.24, 0.32, 1.0) //
#define as_color float4(0.6, 0.5, 0.7, 1.0) //

// Change sun color here
#define sd_color float4(.4, .6, .8, 1.0) //
#define sn_color float4(.3, .3, .6, 1.0) //
#define ss_color float4(1., .6, .0, 1.0) //

// Change specular light color here
#define sld_color float4(1.0, 1.0, 0.8, 1.0) //
#define sln_color float4(0.3, 0.3, 0.6, 1.0) //
#define sls_color float4(1.0, 1.0, 0.8, 1.0) //

// Sky expansion threshold, any higher than the default value will cause repeated crashes
#define skyMax 0.5
#define skyMin 0.125

// Cloud alpha gradient
#define gradientA1 1.0
#define gradientA2 0.64

// Cloud brightness gradient
#define gradientB1 1.0
#define gradientB2 0.8

// Debugging section /// Used for experimental tests only
// #define DEBUG