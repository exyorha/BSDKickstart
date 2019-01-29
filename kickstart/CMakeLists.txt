add_executable(kickstart
  kickstart.S
  lz4.c.inc
  lz4.h
  lz4_wrapper.c
)

target_compile_options(kickstart PRIVATE -Os -Wall -W -ffreestanding -march=armv7-a -mthumb -fPIC -fvisibility=hidden -mno-unaligned-access)
set_target_properties(kickstart PROPERTIES LINK_FLAGS "-nostdlib -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/kickstart.lds,-z,max-page-size=256,--emit-relocs")
set_target_properties(kickstart PROPERTIES LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/kickstart.lds")
set_target_properties(kickstart PROPERTIES C_STANDARD 11)

install(TARGETS kickstart EXPORT kickstart DESTINATION share/bsdbootimagebuilder)
