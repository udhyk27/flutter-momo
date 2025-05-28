cmake_minimum_required(VERSION 3.4.1)

add_library(
        native
        SHARED
        ../ios/Runner/Classes/native.cpp
)

add_compile_options(-Wno-write-strings -Wwritable-strings)
set_target_properties(native PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI})
