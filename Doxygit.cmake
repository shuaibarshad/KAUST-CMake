# used by DoxygenRule.cmake, don't use directly

# The next two lines are deprecated, remove when all doc projects use
# .gitexternals
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/oss)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/common)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/common/oss)

find_package(Git)
if(NOT GIT_EXECUTABLE)
  return()
endif()

include(CommonProcess)
include(Maturity)

configure_file("${CMAKE_CURRENT_LIST_DIR}/github.css"
  "${CMAKE_SOURCE_DIR}/CMake/github.css" COPYONLY)
common_process("Copy icons to documentation repository" FATAL_ERROR
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_LIST_DIR}/icons
  ${CMAKE_SOURCE_DIR}/images)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/index.html"
"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd\">\n"
"<html>\n"
"  <head>\n"
"    <title>${CMAKE_PROJECT_NAME} Software Directory</title>\n"
"    <link rel=\"stylesheet\" href=\"CMake/github.css\" type=\"text/css\">"
"  </head>\n"
"  <body>\n"
"  <div class=\"toc\">"
"    <h2 style=\"text-align: center;\">Projects</h2>")

file(GLOB Entries RELATIVE ${CMAKE_SOURCE_DIR} *-*)
list(SORT Entries)
list(REVERSE Entries)
set(LAST_Project)
set(BODY)

# generate version table
set(GIT_DOCUMENTATION_INSTALL)
set(LAST_Project)

macro(DOXYGIT_WRITE_ENTRY)
  # Verbose entry in main body
  set(BODY "${BODY} <a name=\"${Project}\"></a><h2>${Project} ${VERSION}</h2>
    <p>${${PROJECT}_DESCRIPTION}</p>")

  # start entry
  file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/index.html"
    "<a href=\"#${Project}\">${Project} ${VERSION}</a>
    <div class=\"badges\">")
  set(BODY "${BODY}
    <div class=\"factoid\"><a href=\"${Entry}/index.html\"><img src=\"images/help.png\"> API Documentation</a></div>")

  if(${PROJECT}_GIT_ROOT_URL)
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/index.html"
      "<a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Git source repository\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Git source repository\"> git repository</a></div>")
  endif()

  if(${PROJECT}_ISSUES_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_ISSUES_URL}\"><img src=\"images/search.png\" alt=\"Project Issues\"> Project Issues</a></div>")
  endif()

  if(${PROJECT}_PACKAGE_URL)
    file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/index.html"
      "<a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"> Packages</a></div>")
  endif()

  if(${PROJECT}_CI_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_CI_URL}\"><img src=\"${${PROJECT}_CI_PNG}\" alt=\"Continuous Integration\"> Continuous Integration</a></div>")
  endif()

  if(EXISTS "${CMAKE_SOURCE_DIR}/${Entry}/CoverageReport/index.html")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${Entry}/CoverageReport/index.html\"><img src=\"images/search.png\" alt=\"Test Coverage Report\"> Test Coverage Report</a></div>")
  endif()

  file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/index.html"
    "<a href=\"${Entry}/index.html\"><img src=\"images/help.png\"></a>
      <img src=\"images/${MATURITY}.png\" alt=\"${MATURITY_LONG}\">
    </div><div class=\"flush\"></div>")
  set(BODY "${BODY}
    <div class=\"factoid\"><img src=\"images/${MATURITY}.png\" alt=\"${MATURITY_LONG}\"> ${MATURITY_LONG} Code Quality</div>")

endmacro()

foreach(Entry ${Entries})
  string(REGEX REPLACE "^(.+)-.+$" "\\1" Project ${Entry})
  string(REGEX REPLACE "^.+-(.+)$" "\\1" VERSION ${Entry})
  string(TOUPPER ${Entry} ENTRY)
  string(TOUPPER ${Project} PROJECT)
  set(${PROJECT}_MATURITY "EP")
  if(EXISTS ${CMAKE_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
    include(${CMAKE_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
  endif()
  set(MATURITY ${${PROJECT}_MATURITY})
  set(MATURITY_LONG ${MATURITY_${MATURITY}})

  if(NOT Project STREQUAL LAST_Project) # start new toc entry
    if(LAST_Project) # close previous
      set(BODY "${BODY}</div><div class=\"flush\">")
    endif()
    doxygit_write_entry()
    set(BODY "${BODY}<div class=\"factoid\"><img src=\"images/help.png\"> Old Versions:")

    set(LAST_Project ${Project})
  else()
    set(BODY "${BODY} <a href=\"${Entry}/index.html\">${VERSION}</a>")
  endif()

  list(APPEND GIT_DOCUMENTATION_INSTALL ${Entry})
endforeach()

file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/index.html" "
  </div>
  <div class=\"content\">
    <h1>${CMAKE_PROJECT_NAME} Software Directory</h1>
    ${BODY}</div>
</html>")

configure_file("${CMAKE_CURRENT_BINARY_DIR}/index.html"
  "${CMAKE_SOURCE_DIR}/index.html" COPYONLY)

execute_process(COMMAND "${GIT_EXECUTABLE}" add images ${Entries}
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

# hack to detect that not invoked as script and not under CI
if(VERSION_MAJOR)
  if(NOT "$ENV{TRAVIS}")
    foreach(FOLDER ${GIT_DOCUMENTATION_INSTALL})
      install(DIRECTORY ${FOLDER} DESTINATION share/${CMAKE_PROJECT_NAME}
        CONFIGURATIONS Release)
    endforeach()
  endif()
  install(FILES index.html DESTINATION share/${CMAKE_PROJECT_NAME}
    CONFIGURATIONS Release)
endif()
