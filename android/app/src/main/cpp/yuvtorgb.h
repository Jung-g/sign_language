#ifndef YUVTORGB_H
#define YUVTORGB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 외부에서 호출 가능한 함수만 선언
void convert_yuv_to_rgb(
    const uint8_t* y_plane,
    const uint8_t* u_plane,
    const uint8_t* v_plane,
    int width,
    int height,
    int y_stride,
    int uv_stride,
    int uv_height,
    uint8_t* rgb_out
);

#ifdef __cplusplus
}
#endif

#endif // YUVTORGB_H
