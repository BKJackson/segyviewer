include(${CMAKE_SOURCE_DIR}/cmake/find_python_module.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/python_module_version.cmake)

function(to_path_list var path1)
    if("${CMAKE_HOST_SYSTEM}" MATCHES ".*Windows.*")
        set(sep "\\;")
    else()
        set(sep ":")
    endif()
    set(result "${path1}") # First element doesn't require separator at all...
    foreach(path ${ARGN})
        set(result "${result}${sep}${path}") # .. but other elements do.
    endforeach()
    set(${var} "${result}" PARENT_SCOPE)
endfunction()

find_package(PythonInterp)
find_package(PythonLibs REQUIRED)

configure_file(${CMAKE_SOURCE_DIR}/cmake/test_runner.py ${CMAKE_BINARY_DIR}/tests/test_runner.py COPYONLY)

if (EXISTS "/etc/debian_version")
    set( PYTHON_PACKAGE_PATH "dist-packages")
else()
    set( PYTHON_PACKAGE_PATH "site-packages")
endif()
set(PYTHON_INSTALL_PREFIX "lib/python${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}/${PYTHON_PACKAGE_PATH}" CACHE STRING "Subdirectory to install Python modules in")

function(add_python_package PACKAGE_NAME PACKAGE_PATH PYTHON_FILES)
    add_custom_target(package_${PACKAGE_NAME} ALL)

    foreach (file ${PYTHON_FILES})
        add_custom_command(TARGET package_${PACKAGE_NAME}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/python/${PACKAGE_PATH}
                COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${file} ${CMAKE_BINARY_DIR}/python/${PACKAGE_PATH}
                )
    endforeach ()
    set_target_properties(package_${PACKAGE_NAME} PROPERTIES PACKAGE_INSTALL_PATH ${CMAKE_INSTALL_PREFIX}/${PYTHON_INSTALL_PREFIX}/${PACKAGE_PATH})
    install(FILES ${PYTHON_FILES} DESTINATION ${CMAKE_INSTALL_PREFIX}/${PYTHON_INSTALL_PREFIX}/${PACKAGE_PATH})
endfunction()

function(add_python_test TESTNAME PYTHON_TEST_FILE)
    configure_file(${PYTHON_TEST_FILE} ${PYTHON_TEST_FILE} COPYONLY)
        
    add_test(NAME ${TESTNAME}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tests
            COMMAND python test_runner.py ${PYTHON_TEST_FILE}
            )

    to_path_list(pythonpath "${CMAKE_BINARY_DIR}/python" "$ENV{PYTHONPATH}")
    set_tests_properties(${TESTNAME} PROPERTIES ENVIRONMENT "PYTHONPATH=${pythonpath}")
endfunction()

function(add_python_example TESTNAME PYTHON_TEST_FILE)
    configure_file(${PYTHON_TEST_FILE} ${PYTHON_TEST_FILE} COPYONLY)

    add_test(NAME ${TESTNAME}
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/examples
            COMMAND python ${PYTHON_TEST_FILE} ${ARGN}
            )
    to_path_list(pythonpath "${CMAKE_BINARY_DIR}/python" "$ENV{PYTHONPATH}")
    set_tests_properties(${TESTNAME} PROPERTIES ENVIRONMENT "PYTHONPATH=${pythonpath}")
endfunction()
