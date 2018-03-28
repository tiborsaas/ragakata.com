#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture;
uniform sampler2D u_noise_texture;

/*
	A Fitzhugh-Nagumo reaction-diffusion system.
	See this paper for additional information:

	http://arxiv.org/pdf/patt-sol/9401002.pdf

	A large timestep is used to make the system evolve at an interactive rate when limited to 60 FPS.
    The system is unstable using a large timestep with simple Euler integration, so instead it is
    updated with an exponentially-weighted moving average of the gradient (with time constant tc).
*/


float getColumn( vec2 uv )
{
    float col = 0.0;
    if( uv.x > u_mouse.x && uv.x < u_mouse.x + .5 ){
    	col = 1.0;
    } else {
    	col = 0.0;
    }
	return col;
}


void main()
{
    const float _K0 = -20.0/6.0; // center weight
    const float _K1 = 4.0/6.0; // edge-neighbors
    const float _K2 = 1.0/6.0; // vertex-neighbors
    const float timestep = .7;
    const float a0 = -0.1;
    const float a1 = 2.0;
    const float epsilon = 0.05;
    const float delta = 3.0;
    const float k1 = 1.0;
    const float k2 = 0.0;
    const float k3 = 1.0;
    const float tc = 0.8;

    vec2 mouse = u_mouse.xy / u_resolution.xy;
    vec2 vUv = gl_FragCoord.xy / u_resolution.xy;
    vec2 texel = 1. / u_resolution.xy;

    // 3x3 neighborhood coordinates
    float step_x = texel.x;
    float step_y = texel.y;
    vec2 n  = vec2(0.0, step_y);
    vec2 ne = vec2(step_x, step_y);
    vec2 e  = vec2(step_x, 0.0);
    vec2 se = vec2(step_x, -step_y);
    vec2 s  = vec2(0.0, -step_y);
    vec2 sw = vec2(-step_x, -step_y);
    vec2 w  = vec2(-step_x, 0.0);
    vec2 nw = vec2(-step_x, step_y);

    vec4 uv =    texture2D(u_texture, vUv);
    vec4 uv_n =  texture2D(u_texture, vUv+n);
    vec4 uv_e =  texture2D(u_texture, vUv+e);
    vec4 uv_s =  texture2D(u_texture, vUv+s);
    vec4 uv_w =  texture2D(u_texture, vUv+w);
    vec4 uv_nw = texture2D(u_texture, vUv+nw);
    vec4 uv_sw = texture2D(u_texture, vUv+sw);
    vec4 uv_ne = texture2D(u_texture, vUv+ne);
    vec4 uv_se = texture2D(u_texture, vUv+se);

    // laplacian of all components
    vec4 lapl  = _K0*uv + _K1*(uv_n + uv_e + uv_w + uv_s) + _K2*(uv_nw + uv_sw + uv_ne + uv_se);

    float a = uv.x;
    float b = uv.y;
    float c = uv.z;
    float d = uv.w;

    float d_a = k1*a - k2*a*a - a*a*a - b + lapl.x;
    float d_b = epsilon*(k3*a - a1*b - a0) + delta*lapl.y;
	c = tc * c + (1.0 - tc) * d_a;
	d = tc * d + (1.0 - tc) * d_b;

    a = a + timestep * c;
    b = b + timestep * d;

    if ( mod( floor(u_time), 1.0 ) == 0.0 ) {
    	float mLen = length(u_mouse.xy - gl_FragCoord.xy);
    	a += exp(-mLen * mLen / 10000.0);
       	a += getColumn(vUv);
    }

    // initialize with noise
    if(u_time < 3.) {
        gl_FragColor = texture2D(u_noise_texture, vUv);
    } else {
        gl_FragColor = clamp(vec4(a, b, c, d), -1., 1.);
    }
}