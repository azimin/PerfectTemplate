//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

import SQLite

private let dbPath = "database"


// Create HTTP server.
let server = HTTPServer()

// Register your own routes and handlers
var routes = Routes()
routes.add(method: .get, uri: "/", handler: {
		request, response in
		response.setHeader(.contentType, value: "text/html")
		response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
		response.completed()
	}
)

routes.add(method: .get, uri: "/cookies/set", handler: {
  request, response in
  
  let cookie = HTTPCookie(name: "my-key", value: "5", domain: nil,
                          expires: .session, path: "/",
                          secure: false, httpOnly: false)
  response.addCookie(cookie)
  
  response.completed()
})

routes.add(method: .get, uri: "/cookies/get", handler: {
  request, response in
  
  for (cookieName, cookieValue) in request.cookies {
    print(cookieName, cookieValue)
  }
  
  response.completed()
  
})

routes.add(method: .get, uri: "/load", handler: {
  request, response in
  response.setHeader(.contentType, value: "text/html")
  
  var result = Set<String>()
  
  do {
    let sqlite = try SQLite(dbPath)
    defer {
      sqlite.close() // This makes sure we close our connection.
    }
    
    let selectAll = "SELECT * FROM test"
    
    try sqlite.forEachRow(statement: selectAll, handleRow: { (statement: SQLiteStmt, row: Int) in
      result.insert(statement.columnText(position: 0))
    })
    
  } catch {
    //Handle Errors
  }
  
  var text = result.reduce("", { $0 + $1 + ", " })
  
  if text.characters.count > 2 {
    text.removeSubrange(text.index(text.endIndex, offsetBy: -2)..<text.endIndex)
  }
  
  response.appendBody(string: "<html><title></title><body>Best people: \(text)</body></html>")
  response.completed()
})


routes.add(method: .get, uri: "/add-name", handler: {
  request, response in
  
  response.setHeader(.contentType, value: "application/json")
  
  var success = false
  var result = ""
  
  var data: [String: Any] = ["success": success]
  
  defer {
    do {
      try response.setBody(json: data)
    } catch {
      //...
    }
    
    response.completed()
  }
  
  guard let name = request.param(name: "name") else {
    return
  }
  
  do {
    let sqlite = try SQLite(dbPath)
    defer {
      sqlite.close() // This makes sure we close our connection.
    }
    
    try sqlite.execute(statement: "CREATE TABLE IF NOT EXISTS test (value TEXT NOT NULL)")
    try sqlite.execute(statement: "INSERT INTO test (value) VALUES ('\(name)')")
    
    success = true
    
  } catch let error {
    let sqliteError = (error as? SQLiteError)
    
    if let sqliteError = sqliteError {
      switch sqliteError {
      case .Error(let code, let msg):
        result = msg + " \(code)"
      }
    }
  }
  
  data = ["success": success]
})

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port of 8181
server.serverPort = 8181

// Set a document root.
// This is optional. If you do not want to serve static content then do not set this.
// Setting the document root will automatically add a static file handler for the route /**
server.documentRoot = "./webroot"

// Gather command line options and further configure the server.
// Run the server with --help to see the list of supported arguments.
// Command line arguments will supplant any of the values set above.
configureServer(server)

server.setResponseFilters([(Filter404(), .high)])

do {
	// Launch the HTTP server.
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}
