// DON'T MESS THIS AREA OF CODE //
#define hfloat highp float
#define hvec2 highp vec2
#define hvec3 highp vec3
#define hvec4 highp vec4

#define mfloat mediump float
#define mvec2 mediump vec2
#define mvec3 mediump vec3
#define mvec4 mediump vec4

#define lfloat lowp float
#define lvec2 lowp vec2
#define lvec3 lowp vec3
#define lvec4 lowp vec4
// DON'T MESS THIS AREA OF CODE //

// Global precision variables
// Anything that affects performance goes here
// Default to high
uniform hfloat TOTAL_REAL_WORLD_TIME;
hfloat rainA, nightA, dayA, unLit, Value;

// Default to none
vec4 final;

// Varying variable precisions
#define COLORP mvec4
#define CALPHAP mfloat

// Position precision
#define POS3P hvec3
#define POS2P hvec2