#include <stdlib.h>
#include <stdint.h>
#include "yuvtorgb.h"

typedef enum { YUV_UNKNOWN, YUV444, YUV422, YUV420 } YUVFormat;

// 변환 후 RGB값 0 ~ 255 범위 내부에 있도록 조절
static inline uint8_t clamp255(float val) {
    if (val < 0.0f) return 0;
    if (val > 255.0f) return 255;
    return (uint8_t)(val + 0.5f);
}

// 들어온 이미지의 포맷 찾기
YUVFormat detect_yuv_format(int y_stride, int uv_stride, int height, int uv_height) {
    if (uv_stride == y_stride && uv_height == height) {
        return YUV444;
    } else if (uv_stride == y_stride / 2 && uv_height == height) {
        return YUV422;
    } else if (uv_stride == y_stride / 2 && uv_height == height / 2) {
        return YUV420;
    } else {
        return YUV_UNKNOWN;
    }
}

// U, V 업스케일링
void upscaling_yuv444(
    const uint8_t* u_in, const uint8_t* v_in,
    int width, int height,
    int uv_stride,
    uint8_t* u_out, uint8_t* v_out,
    YUVFormat fmt
) {
    for (int y = 0; y < height; y++) {
        int src_y = (fmt == YUV420) ? (y >> 1) : y;
        for (int x = 0; x < width; x++) {
            int src_x = (fmt == YUV444) ? x : (x >> 1);
            int uv_index = src_y * uv_stride + src_x;
            int out_index = y * width + x;

            u_out[out_index] = u_in[uv_index];
            v_out[out_index] = v_in[uv_index];
        }
    }
}

// YUV444를 RGB로 변환
void convert_yuv444_to_rgb(
    const uint8_t* y_plane,   // Y
    const uint8_t* u_plane,   // 업스케일된 U
    const uint8_t* v_plane,   // 업스케일된 V
    int width,
    int height,
    int y_stride,
    uint8_t* rgb_out          // 출력 RGB 버퍼
) {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int idx = y * width + x;
            int y_idx = y * y_stride + x;

            // 색상 중심 보정(U, V 기본 중심값 128)
            float Y = (float)y_plane[y_idx];
            float U = (float)u_plane[idx] - 128.0f;
            float V = (float)v_plane[idx] - 128.0f;

            // TTA에서 찾은 변환 공식 적용
            float Rf = Y + 0.956f * U + 0.621f * V;
            float Gf = Y - 0.272f * U - 0.647f * V;
            float Bf = Y + 1.106f * U + 1.703f * V;

            int rgb_idx = idx * 3;
            rgb_out[rgb_idx + 0] = clamp255(Rf);  // R
            rgb_out[rgb_idx + 1] = clamp255(Gf);  // G
            rgb_out[rgb_idx + 2] = clamp255(Bf);  // B
        }
    }
}

// YUV → RGB 변환
void convert_yuv_to_rgb(
    const uint8_t* y_plane,   // Y
    const uint8_t* u_plane,   // 업스케일된 U
    const uint8_t* v_plane,   // 업스케일된 V
    int width,
    int height,
    int y_stride,
    int uv_stride,
    int uv_height,
    uint8_t* rgb_out
) {
    YUVFormat fmt = detect_yuv_format(y_stride, uv_stride, height, uv_height);
    if (fmt == YUV_UNKNOWN) {
        for (int i = 0; i < width * height * 3; i += 3) {
            rgb_out[i + 0] = 128; // R
            rgb_out[i + 1] = 128; // G
            rgb_out[i + 2] = 128; // B
        }
        return;
    }

    uint8_t* u444 = malloc(width * height);
    uint8_t* v444 = malloc(width * height);

    upscaling_yuv444(u_plane, v_plane, width, height, uv_stride, u444, v444, fmt);

    convert_yuv444_to_rgb(y_plane, u444, v444, width, height, y_stride, rgb_out);

    free(u444);
    free(v444);
}
