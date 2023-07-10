# Example:
#   merge_headers(merged.h a.h b.h c.h)
include(GitCommitHash)

function(merge_headers)
  # Extact merged header file name
  set(merged ${ARGV0})
  list(REMOVE_AT ARGV 0)

  math(EXPR input_header_count "${ARGC} - 1")
  message(STATUS "Merging ${input_header_count} headers into ${merged}")

  # Here we create a new file
  file(WRITE ${merged} "/* This file is generated by CMake. Do not edit. */\n\n")

  # Add a new header-only library
  get_filename_component(merged_file_name ${merged} NAME)
  string(REGEX REPLACE "\\.[^.]*$" "" merged_interface_lib ${merged_file_name})
  message(STATUS "Generating interface library: ${merged_interface_lib}")
  add_library(${merged_interface_lib} INTERFACE)
  get_filename_component(merged_dir ${merged} DIRECTORY)
  set_target_properties(${merged_interface_lib}
    PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${merged_dir})

  # Define guard
  string(TOUPPER ${merged_file_name} merged_file_name_upper)
  string(REGEX REPLACE "[^A-Z0-9_]" "_" merged_file_name_upper ${merged_file_name_upper})
  string(CONCAT merged_file_define_guard "__" ${merged_file_name_upper} "__")

  file(APPEND ${merged} "#ifndef ${merged_file_define_guard}\n")
  file(APPEND ${merged} "#define ${merged_file_define_guard}\n\n")

  # git commit hash
  git_commit_hash()
  string(TOUPPER ${merged_interface_lib} merged_interface_lib_upper)
  file(APPEND ${merged} "#define ${merged_interface_lib_upper}_GIT_COMMIT_HASH \"${GIT_COMMIT_HASH}\"\n\n")

  # Merge headers
  foreach(header ${ARGV})
    file(READ ${header} content)
    file(APPEND ${merged} "/* Begin: ${header} */\n")
    file(APPEND ${merged} "${content}")
    file(APPEND ${merged} "\n/* End: ${header} */\n\n")

    target_sources(${merged_interface_lib} INTERFACE ${header})

    message(STATUS "Merging: ${header}")
  endforeach()

  # End of define guard
  file(APPEND ${merged} "#endif /* ${merged_file_define_guard} */\n")

  set_source_files_properties(${merged} PROPERTIES GENERATED TRUE)
  set_source_files_properties(${merged} PROPERTIES HEADER_FILE_ONLY TRUE)
endfunction()