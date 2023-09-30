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
To infuse a model into your scene, simply start with CreamyView. This view adopts the size of its parent container and expects a model builder as an input argument. With a design principle that mirrors SwiftUI's Image modifiers, interacting with your model feels natural and intuitive. For instance, the `.resizable()` modifier scales your model to occupy the entire container space.

## 🔍 Technical Details
* File Support: Currently, only the STL and OBJ file formats are supported.
* Camera Details: An orthographic camera is calibrated to the view size and coordinated like its SwiftUI counterpart.
* Mesh Information: The library leans on ModelIO for both model loading and generation.
* Rendering: Rendering is based on Metal with MetalKit.

## 🚧 Work in Progress (Ordered by Priority)
- [ ] ~Scene background customization.~ (Just use `.background` of the View)
- [X] Modifiers: `offset`, `rotationEffect`, `rotation3DEffect`.
- [X] Modifiers: `frame` and `padding`.
- [ ] Materials composition
- [ ] More materials support
- [ ] Animations support (Currently supported using Animatable modifier on the parent View)
- [ ] Multiple Meshes support
- [ ] Bloom effect support

## 🤔 Features under Consideration
* MetalFX upscale for performance optimization
* Clonner, which repeats Meshes. Example:
```Swift
Clonner(.grid(.init(x: 10, y: 10, z: 10)), spacing: 16.0) {
    Mesh(source: .sphere)
        .resizable()
        .frame(width: 50.0, height: 50.0)
}
```
