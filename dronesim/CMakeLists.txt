cmake_minimum_required(VERSION 3.16)

project(DroneSim)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(mujoco REQUIRED)

# Eigen3 is header-only — use the copy bundled in the MuJoCo source tree
set(EIGEN3_INCLUDE_DIR "/home/marc-andre/tools/mujoco/build/_deps/eigen3-src"
    CACHE PATH "Path to Eigen3 headers")

# GLFW bundled in the MuJoCo source build (no install step was run)
set(GLFW_INC "/home/marc-andre/tools/mujoco/build/_deps/glfw3-src/include")
set(GLFW_LIB "/home/marc-andre/tools/mujoco/build/lib/libglfw3.a")

add_executable(sim
  src/main.cpp
  src/render/render.cpp
  src/render/ui.cpp
  src/render/callbacks.cpp
  src/control/control.cpp
  src/control/hover.cpp
  src/control/system_id.cpp
  src/control/lqr.cpp
)

target_include_directories(sim PRIVATE
  ${GLFW_INC}
  ${CMAKE_SOURCE_DIR}/inc
  ${EIGEN3_INCLUDE_DIR}
)

target_link_libraries(sim PRIVATE
  mujoco::mujoco
  ${GLFW_LIB}
  GL
  dl
  pthread
  X11
)

target_compile_features(sim PRIVATE cxx_std_17)

file(COPY assets DESTINATION ${CMAKE_BINARY_DIR})
