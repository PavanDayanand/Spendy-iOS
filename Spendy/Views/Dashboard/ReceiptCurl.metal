#include <metal_stdlib>
using namespace metal;

// The paper bows across its width near the feed, then relaxes to a flat sheet.
[[ stitchable ]] float2 receiptCurl(float2 position, float2 size, float amount) {
    float y = clamp(position.y / max(size.y, 1.0), 0.0, 1.0);
    float across = (position.x / max(size.x, 1.0) - 0.5) * 2.0;
    float bow = sin(y * M_PI_F) * amount;
    return position + float2(across * 10.0 * bow,
                            (1.0 - across * across) * 20.0 * bow);
}
