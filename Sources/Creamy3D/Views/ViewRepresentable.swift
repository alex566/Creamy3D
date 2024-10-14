//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 14.10.24.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

public protocol ViewRepresentable: UIViewRepresentable where UIViewType == ViewType {
    associatedtype ViewType
    associatedtype UIViewType = ViewType
    
    @MainActor
    func makeView(context: Context) -> ViewType
    
    @MainActor
    func updateView(_ view: ViewType, context: Context)
}

extension ViewRepresentable {
    @MainActor
    public func makeUIView(context: Context) -> UIViewType {
        makeView(context: context)
    }
    
    @MainActor
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        updateView(uiView, context: context)
    }
}
#elseif os(macOS)
import AppKit

public protocol ViewRepresentable: NSViewRepresentable where NSViewType == ViewType {
    associatedtype ViewType
    associatedtype NSViewType = ViewType
    
    @MainActor
    func makeView(context: Context) -> ViewType
    
    @MainActor
    func updateView(_ view: ViewType, context: Context)
}

extension ViewRepresentable {

    @MainActor
    public func makeNSView(context: Context) -> NSViewType {
        makeView(context: context)
    }
    
    @MainActor
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        updateView(nsView, context: context)
    }
}
#endif
