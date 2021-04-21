﻿#ifndef NOISE4D_INCLUDED
#define NOISE4D_INCLUDED


float3 mod289(float3 x)
{
	return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float mod289(float x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x)
{
    return mod289(((x * 34.0) + 1.0) * x);
}

float permute(float x)
{
    return mod289(((x * 34.0) + 1.0) * x);
}

float4 taylorInvSqrt(float4 r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
    return 1.79284291400159 - 0.85373472095314 * r;
}

float4 grad4(float j, float4 ip)
{
    const float4 ones = float4(1.0, 1.0, 1.0, -1.0);
    float4 p, s;

    p.xyz = floor(frac((j).xxx * ip.xyz) * 7.0) * ip.z - 1.0;
    p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
    s = float4(p < 0.0);
    p.xyz = p.xyz + (s.xyz * 2.0 - 1.0) * s.www;

    return p;
}

float snoise(float3 v)
{
	const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
	const float4 D = float4(0.0, 0.5, 1.0, 2.0);

	float3 i  = floor(v + dot(v, C.yyy));
	float3 x0 = v   - i + dot(i, C.xxx); 
	
	float3 g = step(x0.yzx, x0.xyz);
	float3 l = 1.0 - g;
	float3 i1 = min(g.xyz, l.zxy);
	float3 i2 = max(g.xyz, l.zxy);

	//     x0 = x0 - 0. + 0.0 * C 
	float3 x1 = x0 - i1 + 1.0 * C.xxx; 
	float3 x2 = x0 - i2 + 2.0 * C.xxx; 
	float3 x3 = x0 - 1. + 3.0 * C.xxx; 

	i = mod289(i);
	float4 p = permute(permute(permute(
		  i.z + float4(0.0, i1.z, i2.z, 1.0))
		+ i.y + float4(0.0, i1.y, i2.y, 1.0))
		+ i.x + float4(0.0, i1.x, i2.x, 1.0));

	float  n_ = 0.142857142857; // 1.0 / 7.0
	float3 ns = n_ * D.wyz - D.xzx;

	float4 j = p - 49.0 * floor(p * ns.z * ns.z);	// fmod(p, 7*7)

	float4 x_ = floor(j * ns.z);
	float4 y_ = floor(j - 7.0 * x_); // fmod(j, N)

	float4 x = x_ * ns.x + ns.yyyy;
	float4 y = y_ * ns.x + ns.yyyy;
	float4 h = 1.0 - abs(x) - abs(y);

	float4 b0 = float4(x.xy, y.xy);
	float4 b1 = float4(x.zw, y.zw);

	float4 s0 = floor(b0) * 2.0 + 1.0;
	float4 s1 = floor(b1) * 2.0 + 1.0;
	float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));

	float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
	float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

	float3 p0 = float3(a0.xy, h.x);
	float3 p1 = float3(a0.zw, h.y);
	float3 p2 = float3(a1.xy, h.z);
	float3 p3 = float3(a1.zw, h.w);

	float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
	m = m * m;

	return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1),
		dot(p2, x2), dot(p3, x3)));
}

// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451

float snoise(float4 v)
{
    const float4 C = float4(0.138196601125011, // (5 - sqrt(5))/20  G4
		0.276393202250021, // 2 * G4
		0.414589803375032, // 3 * G4
		-0.447213595499958); // -1 + 4 * G4

							 // First corner
    float4 i = floor(v + dot(v, (F4).xxxx));
    float4 x0 = v - i + dot(i, C.xxxx);

	// Other corners

	// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
    float4 i0;
    float3 isX = step(x0.yzw, x0.xxx);
    float3 isYZ = step(x0.zww, x0.yyz);
	//  i0.x = dot( isX, float3( 1.0 ) );
    i0.x = isX.x + isX.y + isX.z;
    i0.yzw = 1.0 - isX;
	//  i0.y += dot( isYZ.xy, float2( 1.0 ) );
    i0.y += isYZ.x + isYZ.y;
    i0.zw += 1.0 - isYZ.xy;
    i0.z += isYZ.z;
    i0.w += 1.0 - isYZ.z;

	// i0 now contains the unique values 0,1,2,3 in each channel
    float4 i3 = clamp(i0, 0.0, 1.0);
    float4 i2 = clamp(i0 - 1.0, 0.0, 1.0);
    float4 i1 = clamp(i0 - 2.0, 0.0, 1.0);

	//  x0 = x0 - 0.0 + 0.0 * C.xxxx
	//  x1 = x0 - i1  + 1.0 * C.xxxx
	//  x2 = x0 - i2  + 2.0 * C.xxxx
	//  x3 = x0 - i3  + 3.0 * C.xxxx
	//  x4 = x0 - 1.0 + 4.0 * C.xxxx
    float4 x1 = x0 - i1 + C.xxxx;
    float4 x2 = x0 - i2 + C.yyyy;
    float4 x3 = x0 - i3 + C.zzzz;
    float4 x4 = x0 + C.wwww;

	// Permutations
    i = mod289(i);
    float j0 = permute(permute(permute(permute(i.w) + i.z) + i.y) + i.x);
    float4 j1 = permute(permute(permute(permute(
		i.w + float4(i1.w, i2.w, i3.w, 1.0))
		+ i.z + float4(i1.z, i2.z, i3.z, 1.0))
		+ i.y + float4(i1.y, i2.y, i3.y, 1.0))
		+ i.x + float4(i1.x, i2.x, i3.x, 1.0));

	// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
	// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
    float4 ip = float4(1.0 / 294.0, 1.0 / 49.0, 1.0 / 7.0, 0.0);

    float4 p0 = grad4(j0, ip);
    float4 p1 = grad4(j1.x, ip);
    float4 p2 = grad4(j1.y, ip);
    float4 p3 = grad4(j1.z, ip);
    float4 p4 = grad4(j1.w, ip);

	// Normalise gradients
    float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    p4 *= taylorInvSqrt(dot(p4, p4));

	// Mix contributions from the five corners
    float3 m0 = max(0.6 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
    float2 m1 = max(0.6 - float2(dot(x3, x3), dot(x4, x4)), 0.0);
    m0 = m0 * m0;
    m1 = m1 * m1;
    return 49.0 * (dot(m0 * m0, float3(dot(p0, x0), dot(p1, x1), dot(p2, x2)))
		+ dot(m1 * m1, float2(dot(p3, x3), dot(p4, x4))));

}

float2 snoise2D(float4 x)
{
    float s = snoise(x);
    float s1 = snoise(float4(x.y - 19.1, x.z + 33.4, x.x + 47.2, x.w));
    float2 c = float2(s, s1);
    return c;
}

float3 snoise3D(float4 x)
{
    float s = snoise(x);
    float s1 = snoise(float4(x.y - 19.1, x.z + 33.4, x.x + 47.2, x.w));
    float s2 = snoise(float4(x.z + 74.2, x.x - 124.5, x.y + 99.4, x.w));
    float3 c = float3(s, s1, s2);
    return c;
}

float3 curlNoise(float4 p)
{

    const float e = 0.0009765625;
    float4 dx = float4(e, 0.0, 0.0, 0.0);
    float4 dy = float4(0.0, e, 0.0, 0.0);
    float4 dz = float4(0.0, 0.0, e, 0.0);

    float3 p_x0 = snoise3D(p - dx);
    float3 p_x1 = snoise3D(p + dx);
    float3 p_y0 = snoise3D(p - dy);
    float3 p_y1 = snoise3D(p + dy);
    float3 p_z0 = snoise3D(p - dz);
    float3 p_z1 = snoise3D(p + dz);

    float x = p_y1.z - p_y0.z - p_z1.y + p_z0.y;
    float y = p_z1.x - p_z0.x - p_x1.z + p_x0.z;
    float z = p_x1.y - p_x0.y - p_y1.x + p_y0.x;

    const float divisor = 1.0 / (2.0 * e);
    return normalize(float3(x, y, z) * divisor);
}

float3 curlNoise(float3 coord)
{
    const float e = 1e-3;
    float3 dx = float3(e, 0.0, 0.0);
    float3 dy = float3(0.0, e, 0.0);
    float3 dz = float3(0.0, 0.0, e);

    float3 dpdx0 = snoise(coord - dx);
    float3 dpdx1 = snoise(coord + dx);
    float3 dpdy0 = snoise(coord - dy);
    float3 dpdy1 = snoise(coord + dy);
    float3 dpdz0 = snoise(coord - dz);
    float3 dpdz1 = snoise(coord + dz);

    float x = dpdy1.z - dpdy0.z + dpdz1.y - dpdz0.y;
    float y = dpdz1.x - dpdz0.x + dpdx1.z - dpdx0.z;
    float z = dpdx1.y - dpdx0.y + dpdy1.x - dpdy0.x;

    return float3(x, y, z) / e * 2.0;
}

float snoise(float2 v)
{
	const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
		0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
		-0.577350269189626,  // -1.0 + 2.0 * C.x
		0.024390243902439); // 1.0 / 41.0
							// First corner
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);

	// Other corners
	float2 i1;
	i1.x = step(x0.y, x0.x);
	i1.y = 1.0 - i1.x;

	// x1 = x0 - i1  + 1.0 * C.xx;
	// x2 = x0 - 1.0 + 2.0 * C.xx;
	float2 x1 = x0 + C.xx - i1;
	float2 x2 = x0 + C.zz;

	// Permutations
	i = mod289(i); // Avoid truncation effects in permutation
	float3 p =
		permute(permute(i.y + float3(0.0, i1.y, 1.0))
			+ i.x + float3(0.0, i1.x, 1.0));

	float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	m = m * m;
	m = m * m;

	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;

	// Normalise gradients implicitly by scaling m
	m *= taylorInvSqrt(a0 * a0 + h * h);

	// Compute final noise value at P
	float3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.y = a0.y * x1.x + h.y * x1.y;
	g.z = a0.z * x2.x + h.z * x2.y;
	return 130.0 * dot(m, g);
}

float3 snoise_grad(float2 v)
{
	const float4 C = float4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
		0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
		-0.577350269189626,  // -1.0 + 2.0 * C.x
		0.024390243902439); // 1.0 / 41.0
							// First corner
	float2 i = floor(v + dot(v, C.yy));
	float2 x0 = v - i + dot(i, C.xx);

	// Other corners
	float2 i1;
	i1.x = step(x0.y, x0.x);
	i1.y = 1.0 - i1.x;

	// x1 = x0 - i1  + 1.0 * C.xx;
	// x2 = x0 - 1.0 + 2.0 * C.xx;
	float2 x1 = x0 + C.xx - i1;
	float2 x2 = x0 + C.zz;

	// Permutations
	i = mod289(i); // Avoid truncation effects in permutation
	float3 p =
		permute(permute(i.y + float3(0.0, i1.y, 1.0))
			+ i.x + float3(0.0, i1.x, 1.0));

	float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.0);
	float3 m2 = m * m;
	float3 m3 = m2 * m;
	float3 m4 = m2 * m2;

	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	float3 x = 2.0 * frac(p * C.www) - 1.0;
	float3 h = abs(x) - 0.5;
	float3 ox = floor(x + 0.5);
	float3 a0 = x - ox;

	// Normalise gradients
	float3 norm = taylorInvSqrt(a0 * a0 + h * h);
	float2 g0 = float2(a0.x, h.x) * norm.x;
	float2 g1 = float2(a0.y, h.y) * norm.y;
	float2 g2 = float2(a0.z, h.z) * norm.z;

	// Compute noise and gradient at P
	float2 grad =
		-6.0 * m3.x * x0 * dot(x0, g0) + m4.x * g0 +
		-6.0 * m3.y * x1 * dot(x1, g1) + m4.y * g1 +
		-6.0 * m3.z * x2 * dot(x2, g2) + m4.z * g2;
	float3 px = float3(dot(x0, g0), dot(x1, g1), dot(x2, g2));
	return 130.0 * float3(grad, dot(m4, px));
}

#endif