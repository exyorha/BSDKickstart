add_executable(zynq_init
  zynq_init.S
  cache_init.S
)

target_compile_options(zynq_init PRIVATE -Os -Wall -W -ffreestanding -march=armv7-a -mthumb -fPIC -fvisibility=hidden)
set_target_properties(zynq_init PROPERTIES LINK_FLAGS "-nostdlib -Wl,-T,${CMAKE_CURRENT_SOURCE_DIR}/zynq_init.lds,-z,max-page-size=256,--emit-relocs")
set_target_properties(zynq_init PROPERTIES LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/zynq_init.lds")
set_target_properties(zynq_init PROPERTIES C_STANDARD 11)

install(TARGETS zynq_init EXPORT zynq_init DESTINATION share/bsdbootimagebuilder)
