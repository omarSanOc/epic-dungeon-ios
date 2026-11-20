#include <metal_stdlib>
using namespace metal;

struct Vertex { float3 position; float3 normal; float4 color; };
struct Uniforms { float4x4 viewProjection; float4 eye; float4 time; };
struct Varying {
    float4 position [[position]];
    float3 world;
    float3 normal;
    float4 color;
};
vertex Varying dungeonVertex(uint id [[vertex_id]], const device Vertex *vertices [[buffer(0)]],
                             constant Uniforms &u [[buffer(1)]]) {
    Vertex v = vertices[id];
    return {u.viewProjection * float4(v.position,1), v.position, v.normal, v.color};
}
fragment float4 dungeonFragment(Varying v [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    float3 toEye = u.eye.xyz - v.world;
    float distance = length(toEye);
    float3 normal = normalize(v.normal);
    float diffuse = max(dot(normal, normalize(toEye + float3(0,0.4,0))), 0.0);
    float3 light = float3(0.27,0.34,0.38) + float3(1.0,0.79,0.52) * diffuse * (2.5 / (1.0 + distance * distance * 0.13));
    const float3 torches[] = {float3(6.1,1.15,12),float3(10.9,1.15,12),float3(4.6,1.15,7),float3(12.4,1.15,7)};
    for (uint i = 0; i < 4; ++i) {
        float3 delta = torches[i] - v.world;
        float flicker = 1.0 + 0.08 * sin(u.time.x * 8 + float(i));
        light += float3(1.0,0.43,0.12) * max(0.0,dot(normal,normalize(delta))) * 2.2 * flicker / (1.0 + dot(delta,delta));
    }
    float3 color = v.color.rgb * light;
    color = mix(color, v.color.rgb * 1.25, v.color.a);
    float fog = 1.0 - exp(-distance * distance * 0.006);
    color = mix(color, float3(0.035,0.065,0.075), fog);
    return float4(color,1);
}
