/*
Item Highlighter
(c) 2022 OzMaister, MIT License

from:
https://godotshaders.com/shader/collectable-item-shining-highlight/
*/

shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform vec4 shine_color : source_color = vec4( 1.0, 1.0, 1.0, 1.0 );
uniform float cycle_interval : hint_range(0.1, 10.0) = 1.0;
uniform float shine_speed : hint_range(.1, 10.0) = 3.0;
uniform float shine_width : hint_range(1, 100.0) = 3.0;

void fragment( )
{
	vec3 vertex = ( INV_VIEW_MATRIX  * vec4( VERTEX, 1.0 ) ).xyz;
	float width = shine_width * 0.001 * cycle_interval;
	float phase = TIME * shine_speed * cycle_interval;
	float frequency = floor( sin( (vertex.y + vertex.x + vertex.z) * cycle_interval + phase ) + width );
	ALBEDO = shine_color.rgb;
	ALPHA = clamp( ( 1.0 - dot( NORMAL, VIEW ) ) * frequency * shine_color.a, 0.0, 1.0 );
}