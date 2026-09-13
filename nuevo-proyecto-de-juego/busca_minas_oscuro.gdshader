shader_type canvas_item;
// lo de adentro del () es como la posicion inicial, que da igual porque después sigue al mouse
uniform vec2 mouse_pos = vec2(0.5, 0.5);
//tamaño
uniform float radio = 0.12;

void fragment(){
	vec2 pos = SCREEN_UV;
	pos.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	vec2 centro = mouse_pos;
	centro.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

	float distancia = distance(pos, centro);

	if(distancia < radio){
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}else{
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}