//
//  build.swift
//  MetalFloat64
//
//  Created by Philip Turner on 12/12/22.
//

import Foundation
import RegexBuilder

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
  
  func getLines(atPath path: String) -> [Substring] {
    guard let data = fm.contents(atPath: path) else {
      fatalError("Could not find file '\(path)'.")
    }
    let string = String(bytes: data, encoding: .utf8)!
    return string.split(
      separator: "\n", omittingEmptySubsequences: false)
  }
  
  // Extract library header contents.
  let libraryHeaderPath = headersPath + "/" + libraryHeaderName
  let inputLines = getLines(atPath: libraryHeaderPath)
  var output: [Substring] = []
  
  // Replace any includes that have quotations.
  let includePattern = try! Regex("^\\s*#include \\s*\"(\\S*)\"")
  let headerStartPattern = try! Regex("^// MARK: - (.*)")
  for line in inputLines {
    // Get header name from regex, otherwise append to output.
    guard let match = line.firstMatch(of: includePattern) else {
      output.append(line)
      continue
    }
    let headerName = String(match[1].substring!)
    func headerError(_ message: String) -> Never {
      fatalError("Header '\(headerName)' \(message).")
    }
    guard subpaths.contains(headerName) else {
      headerError("not found")
    }
    
    // Extract sub-header contents.
    let headerPath = headersPath + "/" + headerName
    let headerLines = getLines(atPath: headerPath)
    guard headerLines.count >= 2 else {
      headerError("is too short")
    }
    
    // Assert that there aren't extra newlines at the end.
    guard headerLines.last! == "" else {
      headerError("did not end with a newline")
    }
    guard headerLines[headerLines.endIndex - 2].contains(
      where: { !$0.isWhitespace }) else {
      headerError("ended with multiple newlines")
    }
    
    // Enforce a common format to start the header:
    // // MARK: - SUBHEADER_NAME
    // [newline]
    guard headerLines[1] == "" else {
      headerError("needs a newline as its second line")
    }
    let firstLine = (headerLines.first!)
    guard let match = firstLine.firstMatch(of: headerStartPattern) else {
      headerError("had malformatted first line")
    }
    
    // Assert it starts with the correct name.
    let presentName = match[1].substring!
    guard presentName == headerName else {
      headerError("had malformatted first line \(presentName)")
    }
    
    // Append the file's contents to output.
    
    // Assert the following format at the start of the sub-header:
    // // MARK: - SUBHEADER_NAME
    // [newline]
    // Code, cannot be newline or only-whitespace line.
//    let headerData = fm.
    
//     (linting).
  }
  
  // TODO: Overwrite the `MetalFloat64` header with the new one, delete smaller
  // sub-headers.
}
