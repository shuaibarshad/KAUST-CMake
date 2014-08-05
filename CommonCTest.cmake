# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>

include(CommonCPPCTest)

if(COVERAGE)
  coverage_report(run_cpp_tests)
  # workaround: 'make test' does not build tests beforehand
  add_custom_target(tests_${PROJECT_NAME} DEPENDS lcov-html)
else()
  add_custom_target(tests_${PROJECT_NAME} DEPENDS run_cpp_tests)
endif()

set_target_properties(tests_${PROJECT_NAME} PROPERTIES FOLDER "Tests")
