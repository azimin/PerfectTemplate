//
//  requests.swift
//  PerfectTemplate
//
//  Created by Alex Zimin on 01/12/2016.
//
//

import Foundation
import PerfectHTTP
import PerfectHTTPServer

struct Filter404: HTTPResponseFilter {
  func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
    callback(.continue)
  }
  
  func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
    if case .notFound = response.status {
      response.bodyBytes.removeAll()
      response.setBody(string: "The file \(response.request.path) was not found.")
      response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
      callback(.done)
    } else {
      callback(.continue)
    }
  }
}
