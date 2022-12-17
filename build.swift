//
//  build.swift
//  MetalFloat64
//
//  Created by Philip Turner on 12/12/22.
//

import Foundation
import RegexBuilder

// Script for very complex operations during the build process.
// Argument 0 - automatically assigned to this file's name
// Argument 1 - location of the "MetalFloat64" directory to operate on
// Argument 2 - task to perform

guard CommandLine.arguments.count == 3 else {
  fatalError("Invalid argument count.")
}

switch CommandLine.arguments[2] {
case "--merge-float64-headers":
  mergeFloat64Headers()
case "--embed-atomic64-sources":
  embedAtomic64Sources()
default:
  fatalError("Invalid task name.")
}

// Utility function for reading files.
func getLines(atPath path: String) -> [Substring] {
  guard let data = FileManager.default.contents(atPath: path) else {
    fatalError("Could not find file '\(path)'.")
  }
  let string = String(bytes: data, encoding: .utf8)!
  return string.split(
    separator: "\n", omittingEmptySubsequences: false)
}

// Combine all sub-headers into a single-file header.
func mergeFloat64Headers() {
  let currentPath = CommandLine.arguments[1]
  let headersDirectory = currentPath + "/include/MetalFloat64"
  
  // Check for library header.
  let fm = FileManager.default
  let subpaths = try! fm.subpathsOfDirectory(atPath: headersDirectory)
  let libraryHeaderName = "MetalFloat64.h"
  guard subpaths.contains(libraryHeaderName) else {
    fatalError("Could not find '\(libraryHeaderName)'.")
  }
  
  // Extract library header contents.
  let libraryHeaderPath = headersDirectory + "/" + libraryHeaderName
  let inputLines = getLines(atPath: libraryHeaderPath)
  var outputLines: [Substring] = []
  
  // Replace any includes that have quotations.
  let includePattern = try! Regex("^\\s*#include \\s*\"(\\S*)\"")
  let headerStartPattern = try! Regex("^// MARK: - (.*)")
  for line in inputLines {
    // Get header name from regex, otherwise append to output.
    // NOTE: Headers should try to mirror naming conventions from the Metal
    // Standard Library.
    guard let match = line.firstMatch(of: includePattern) else {
      outputLines.append(line)
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
    let headerPath = headersDirectory + "/" + headerName
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
    
    // Append source location directive help with debugging.
    outputLines.append("#line 0 \"\(headerName)\"")
    
    // Append the file's contents to output.
    outputLines.append(contentsOf: headerLines)
  }
  
  // Delete all headers and replace with the single-file header.
  for subpath in subpaths {
    let headerPath = headersDirectory + "/" + subpath
    try! fm.removeItem(atPath: headerPath)
  }
  let output = outputLines.joined(separator: "\n")
  let outputData = output.data(using: .utf8)!
  guard fm.createFile(atPath: libraryHeaderPath, contents: outputData) else {
    fatalError("Error overwriting file '\(libraryHeaderPath)'.")
  }
}

// Copy "Atomic.metal" into "GenerateLibrary.swift" and overwrite the previous
// source file.
func embedAtomic64Sources() {
  let currentPath = CommandLine.arguments[1]
  let sourcesDirectory = currentPath + "/src"
  
  // Check for the source files.
  let fm = FileManager.default
  let subpaths = try! fm.subpathsOfDirectory(atPath: sourcesDirectory)
  let metalSourceName = "Atomic.metal"
  guard subpaths.contains(metalSourceName) else {
    fatalError("Could not find '\(metalSourceName)'.")
  }
  let swiftSourceName = "GenerateLibrary.swift"
  guard subpaths.contains(swiftSourceName) else {
    fatalError("Could not find '\(swiftSourceName)'.")
  }
  
  let metalSourcePath = sourcesDirectory + "/" + metalSourceName
  let swiftSourcePath = sourcesDirectory + "/" + swiftSourceName
  let metalLines = getLines(atPath: metalSourcePath)
  let swiftLines = getLines(atPath: swiftSourcePath)
  
  // Pattern to search for:
  // private let shader_source = """
  // [metal source code]
  // """ // end copying here
  let literalStart = swiftLines.firstIndex(where: {
    $0.starts(with: "private let shader_source = \"\"\"")
  })
  let literalEnd = swiftLines.lastIndex(where: {
    $0.starts(with: "\"\"\" // end copying here")
  })
  guard let literalStart = literalStart,
        let literalEnd = literalEnd else {
    fatalError("Could not locate string literal in Swift source.")
  }
  
  // Piece together chunks of the input files.
  var outputLines: [Substring] = []
  outputLines.append(contentsOf: swiftLines[...literalStart])
  outputLines.append(contentsOf: metalLines)
  outputLines.append(contentsOf: swiftLines[literalEnd...])
  
  // Overwrite the existing source file.
  let output = outputLines.joined(separator: "\n")
  let outputData = output.data(using: .utf8)!
  guard fm.createFile(atPath: swiftSourcePath, contents: outputData) else {
    fatalError("Error overwriting file '\(swiftSourcePath)'.")
  }
}
