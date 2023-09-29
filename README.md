# Creamy3D

## 🌟 Intro
Creamy 3D is a library that allows seamless integration of simple 3D objects into your SwiftUI projects. Spice up your app's UI with interactive icons and 3D visuals. Its material system draws inspiration from Spline.design.

## 🖥️ Code Example
```Swift
CreamyView {
    Mesh(source: .stl("order")) {
        MatcapMaterial(name: "matcap")
    }
    .resizable()
    .scaledToFit()
}
```

## 🛠️ How to Use
To infuse a model into your scene, simply start with CreamyView. This view adopts the size of its parent container and eagerly waits for a model builder argument. With a design principle that mirrors SwiftUI's Image modifiers, interacting with your model feels natural and intuitive. For instance, the .resizable() modifier scales your model to occupy the entire container space.

## 🔍 Technical Details
* File Support: Currently, only the STL and OBJ file formats are supported.
* Camera Details: An orthographic camera is used, calibrated to the view size and coordinated like its SwiftUI counterpart.
* Mesh Information: The library leans on ModelIO for both model loading and generation.
* Rendering: Rendering prowess is derived from MetalKit.

## 🚧 Work in Progress (Ordered by Priority)
- [ ] Scene background customization.
- [X] Modifiers: `offset`, `rotationEffect`, `rotation3DEffect`.
- [ ] Modifiers: `frame` and `padding`.
- [ ] Materials composition
- [ ] Animations support
- [ ] More materials support
- [ ] Multiple Meshes support
- [ ] Bloom effect support

## 🤔 Features under Consideration
* MetalFX upscale for performance optimization
