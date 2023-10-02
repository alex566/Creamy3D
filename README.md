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

## 🎞 Video example
![ezgif com-video-to-gif](https://github.com/alex566/Creamy3D/assets/7542506/dcf7f426-81b1-460f-b8ef-f94d4b2e0a60)

## 🛠️ How to Use
To infuse a model into your scene, simply start with CreamyView. This view adopts the size of its parent container and expects a model builder as an input argument. With a design principle that mirrors SwiftUI's Image modifiers, interacting with your model feels natural and intuitive. For instance, the `.resizable()` modifier scales your model to occupy the entire container space.

## 🔍 Technical Details
* File Support: Currently, only the STL and OBJ file formats are supported.
* Camera Details: An orthographic camera is calibrated to the view size and coordinated like its SwiftUI counterpart.
* Mesh Information: The library leans on ModelIO for both model loading and generation.
* Rendering: Rendering is based on Metal with MetalKit.

## 📜 Planned features
The material system is inspired by spline.design, so the goal is to make any visual appearance reproducible by the library.

| Materials  | Status            |
|------------|-------------------|
| Color      | ✅ done           |
| Matcap     | ✅ done           |
| Fresnel    | 🟡 partially done |
| Texture    | ⚙ in progress     |
| Light      | ⚙ in progress     |
| Normal     | todo              |
| Depth      | todo              |
| Gradient   | todo              |
| Noise      | todo              |
| Rainbow    | todo              |
| Outline    | todo              |
| Glass      | todo              |
| Pattern    | todo              |

All primitive shapes are planned to be generatable out of the box. The way how to handle Models from files is still under consideration. Procedural generation of meshes is in the distant future plans.

| Meshes     | Status            |
|------------|-------------------|
| Sphere     | ✅ done           |
| Cube       | ✅ done           |
| Model      | 🟡 partially done |
| Plane      | todo              |
| Cylinder   | todo              |
| Cone       | todo              |
| ...        | todo              |

The most common post-processing effects are planned, but the list is not full.

| Post processing | Status       |
|-----------------|--------------|
| Bloom           | todo         |
| Aberration      | todo         |
| ...             | todo         |


## 🚧 Work in Progress - v0.3 (Ordered by Priority)
- [ ] ~Scene background customization.~ (Just use `.background` of the View)
- [X] Modifiers: `offset`, `rotationEffect`, `rotation3DEffect`.
- [X] Modifiers: `frame` and `padding`.
- [X] Materials composition
- [ ] Add materials: `fresnel`, `texture`
- [ ] Blend modes: `multiply`, `screen`, `overlay`
- [ ] Add `light` material
- [ ] Animations support out of the box (Currently supported using Animatable modifier on the parent View)
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
