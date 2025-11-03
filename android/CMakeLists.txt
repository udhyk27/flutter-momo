cmake_minimum_required(VERSION 3.22.1)

add_library(
        native
        SHARED
        ../ios/Runner/Classes/native.cpp
)

add_compile_options(-Wno-write-strings -Wwritable-strings)

# 링커 옵션
# target_link_options(native PRIVATE -Wl,-z,max-page-size=16384)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,max-page-size=16384")

# set_target_properties(native PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI})


