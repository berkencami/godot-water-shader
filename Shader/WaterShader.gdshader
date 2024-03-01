shader_type spatial;

uniform vec3 base_color : source_color;
uniform vec3 fresnel_color : source_color;//fresnel color
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0;
uniform sampler2D wave;
uniform sampler2D normal_map;
uniform sampler2D normal_map2;
uniform sampler2D depth_texture : source_color, hint_depth_texture;
uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform vec2 wave_direction = vec2(2.0,0.0);
uniform vec2 wave_direction2 = vec2(2.0,0.0);
uniform float time_scale : hint_range(0.0, 1.0, 0.1) = 0;
uniform float noise_scale = 0;
uniform float high_scale = 0; 

uniform vec4 deep_color : source_color;
uniform vec4 shallow_color : source_color;
uniform float beers_law = 2;
uniform float depth_offset = -1; 

uniform float edge_scale = 0.1;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color;


//varying variables
varying float height;
varying vec3 world_pos;


float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)),0.0,1.0)),amount);
}

float edge(float depth) {
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

void vertex() {
	
	world_pos=(MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	height = texture(wave,world_pos.xz / noise_scale + TIME * time_scale).x;
	VERTEX.y += height * high_scale;
}

void fragment() {
	
	float depthTexture = texture(depth_texture,SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depthTexture + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
	float depth_blend_power = clamp(pow(depth_blend,2.5), 0.0 , 1.0);
	vec3 screen_color = textureLod(screen_texture,SCREEN_UV,depth_blend_power * 2.5).xyz;
	vec3 depth_color = mix(shallow_color.xyz, deep_color.xyz, depth_blend_power);
	vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);
	
	
	float z_depth = edge(texture(depth_texture , SCREEN_UV).x);
	float z_pos = edge(FRAGCOORD.z);
	float z_dif = z_depth - z_pos;
	
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	
	vec3 normal_blend = mix(texture(normal_map,UV+ time).xyz,
	 texture(normal_map2,UV + time2).xyz,0.5);
	
	float fresnel = fresnel(5, NORMAL,VIEW);
	
	vec3 surface_color = mix(base_color,fresnel_color,fresnel);
	vec3 new_depth_color = mix(edge_color,color,step(edge_scale, z_dif));
	
	ALBEDO = clamp(surface_color + new_depth_color,vec3(0.0), vec3(1.0));
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	
}
