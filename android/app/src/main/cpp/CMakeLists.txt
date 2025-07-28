cmake_minimum_required(VERSION 3.4.1)

add_library( # 라이브러리 이름과 타겟
    yuvtorgb
    SHARED
    yuvtorgb.c
)

# 헤더 포함 경로 (현재 디렉토리)
target_include_directories(yuvtorgb PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# 로그 라이브러리 필요시 (안드로이드용)
find_library(log-lib log)
target_link_libraries(yuvtorgb ${log-lib})
