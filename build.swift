//
//  build.swift
//  MetalFloat64
//
//  Created by Philip Turner on 12/12/22.
//

import Foundation

// Script for very complex operations during the build process.
// Argument 0 - automatically set to this file's name
// Argument 1 - location of the "MetalFloat64" directory to operate on
// Argument 2 - task to perform

guard CommandLine.arguments.count == 3 else {
  fatalError("Invalid argument count.")
}

switch CommandLine.arguments[2] {
case "--merge-headers":
  mergeHeaders()
default:
  fatalError("Invalid task name.")
}

// Combine all sub-headers into a single-file header.
func mergeHeaders() {
  let currentPath = CommandLine.arguments[1]
  let headersPath = currentPath + "/include/MetalFloat64"
  
  // Check for library header.
  let fm = FileManager.default
  let subpaths = try! fm.subpathsOfDirectory(atPath: headersPath)
  let libraryHeaderName = "MetalFloat64.h"
  guard subpaths.contains(libraryHeaderName) else {
    fatalError("Could not find '\(libraryHeaderName)'.")
  }
  
  // Extract library header contents.
  let libraryHeaderPath = headersPath + "/" + libraryHeaderName
  let inputData = fm.contents(atPath: libraryHeaderPath)!
  let input = String(bytes: inputData, encoding: .utf8)!
  var output = String()
  
  // Replace any includes that have quotations.
  // TODO:
  // Accept multiple whitespaces between the include and actual header.
  // Throw an error when you encounter an invalid include.
  // Assert that there aren't extra newlines at the end (linting).
  // Assert the following format at the start of the sub-header:
  // // MARK: - SUBHEADER_NAME
  // [newline]
  // Code, cannot be newline or only-whitespace line.
  
  // TODO: Overwrite the `MetalFloat64` header with the new one, delete smaller
  // sub-headers.
}
