#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertexShader(const device Vertex *vertices [[buffer(0)]],
                             const device float2 *positions [[buffer(1)]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]]) {
    Vertex vert = vertices[vid];
    float2 position = positions[iid];
    
    VertexOut out;
    out.position = float4(vert.position * 4 + position, 0, 1);
    out.color = vert.color;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
    return in.color;
} 