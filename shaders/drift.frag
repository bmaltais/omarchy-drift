#version 440
// Drifting colour blobs, grain, and weather (rain, snow, fog). All motion comes from `time`.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  vec4 c0; vec4 c1; vec4 c2; vec4 c3; vec4 c4; vec4 c5; vec4 c6; vec4 c7;
  float time;
  float aspect;      // width / height
  float blobs;       // 2..8
  float grain;       // 0..1
  float brightness;  // follow the day, 1 = unchanged
  float warmth;      // -1 cool .. 1 warm
  float desat;       // 0..1, grey the colours (cloud, fog)
  float rain;        // 0..1
  float snow;        // 0..1
};

// Float-only hash of the pixel, 0..1 (no sin, no integer ops: it must compile on every backend).
float pixelNoise(vec2 frag, float seed) {
  vec3 p3 = fract(vec3(frag + seed * vec2(37.0, 91.0), frag.x) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

vec3 colorAt(int i) {
  switch (i) {
    case 0: return c0.rgb; case 1: return c1.rgb; case 2: return c2.rgb; case 3: return c3.rgb;
    case 4: return c4.rgb; case 5: return c5.rgb; case 6: return c6.rgb; default: return c7.rgb;
  }
}

// Drops on glass: one candidate per grid cell, present when the cell's hash is under `amount`.
float drops(vec2 p, float amount, float t) {
  float acc = 0.0;
  for (int layer = 0; layer < 2; layer++) {
    float scale = layer == 0 ? 9.0 : 17.0;
    vec2 q = p * scale + vec2(float(layer) * 7.3, t * (layer == 0 ? 0.03 : 0.05));
    vec2 id = floor(q);
    vec2 f = fract(q) - 0.5;
    float h = hash21(id + float(layer) * 31.0);
    if (h < amount) {
      vec2 off = (vec2(hash21(id + 3.1), hash21(id + 8.7)) - 0.5) * 0.5;
      float r = 0.05 + 0.1 * hash21(id + 1.7);
      float d = length(f - off);
      acc += smoothstep(r, r * 0.55, d) * 0.5 + smoothstep(r * 1.25, r, d) * 0.25;
    }
  }
  return acc;
}

float flakes(vec2 p, float amount, float t) {
  float acc = 0.0;
  for (int layer = 0; layer < 3; layer++) {
    float scale = 14.0 + 11.0 * float(layer);
    vec2 q = p * scale;
    q.y -= t * (0.05 + 0.03 * float(layer));
    q.x += sin(t * 0.07 + q.y * 0.5) * 0.4;
    vec2 id = floor(q);
    vec2 f = fract(q) - 0.5;
    if (hash21(id + float(layer) * 17.0) < amount * 0.2) {
      vec2 off = (vec2(hash21(id + 2.3), hash21(id + 5.9)) - 0.5) * 0.6;
      acc += smoothstep(0.09, 0.02, length(f - off)) * (0.45 + 0.1 * float(layer));
    }
  }
  return acc;
}

void main() {
  vec2 uv = qt_TexCoord0;
  vec2 p = vec2(uv.x * aspect, uv.y);

  vec3 accum = vec3(0.0);
  float wsum = 0.0;
  int n = int(blobs + 0.5);
  for (int i = 0; i < 8; i++) {
    if (i >= n) break;
    float fi = float(i);
    vec2 pos = vec2(0.5 + 0.46 * sin(time * 0.31 * (1.0 + 0.17 * fi) + fi * 2.1),
                    0.5 + 0.46 * cos(time * 0.27 * (1.0 + 0.13 * fi) + fi * 3.7));
    pos.x *= aspect;
    float r = 0.36 + 0.09 * sin(time * 0.2 + fi * 1.3);
    vec2 d = p - pos;
    float w = exp(-dot(d, d) / (r * r));
    accum += colorAt(i) * w;
    wsum += w;
  }
  vec3 col = (accum + colorAt(0) * 0.12) / (wsum + 0.12);

  float luma = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(col, vec3(luma), desat);
  col *= brightness;
  col += vec3(0.09, 0.02, -0.08) * warmth;

  float wet = drops(p, rain * 0.45, time);
  col += vec3(wet * 0.16);
  col *= 1.0 - wet * 0.08 * (1.0 - step(0.3, wet));
  col += vec3(flakes(p, snow, time)) * 0.9;

  // Visible film grain, on the slider.
  col += (pixelNoise(gl_FragCoord.xy, 0.0) - 0.5) * grain * 0.1;
  // Always-on dither of one 8-bit step (triangular), so slow gradients do not band whatever the grain is.
  col += (pixelNoise(gl_FragCoord.xy, 1.0) + pixelNoise(gl_FragCoord.xy, 2.0) - 1.0) / 255.0;
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0) * qt_Opacity;
}
