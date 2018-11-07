add_executable(kickstart
  kickstart.S
  lz4.c.inc
  lz4.h
  lz4_wrapper.c
)

target_compile_options(kickstart PRIVATE -Os -Wall -W -fno-hosted -march=armv7-a -mthumb -fwhole-program)
set_target_properties(kickstart PROPERTIES LINK_FLAGS "-nostdlib -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/kickstart.lds,-z,max-page-size=256,--emit-relocs")
set_target_properties(kickstart PROPERTIES LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/kickstart.lds")

install(TARGETS kickstart EXPORT kickstart DESTINATION share/bsdbootimagebuilder)
