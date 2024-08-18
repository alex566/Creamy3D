//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 17.08.24.
//

import OSLog

@MainActor
extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let sceneLoading = Logger(subsystem: subsystem, category: "loading")
}
