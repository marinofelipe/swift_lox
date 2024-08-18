//
//  RuntimeError.swift
//
//
//  Created by Marino Felipe on 18.08.24.
//

import Foundation

struct RuntimeError: LocalizedError {
  let token: Token
  let message: String

  var errorDescription: String? { message }
}
