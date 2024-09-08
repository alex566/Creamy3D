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
![ezgif com-video-to-gif](https://github.com/alex566/Creamy3D/assets/7542506/4722124f-75a4-4eae-898f-d925e1f850f3)

## 🛠️ How to Use
To infuse a model into your scene, simply start with CreamyView. This view adopts the size of its parent container and expects a model builder as an input argument. With a design principle that mirrors SwiftUI's Image modifiers, interacting with your model feels natural and intuitive. For instance, the `.resizable()` modifier scales your model to occupy the entire container space.

## 🔍 Technical Details
* File Support: Currently, only the STL and OBJ file formats are supported.
* Camera Details: An orthographic camera is calibrated to the view size and coordinated like its SwiftUI counterpart.
* Mesh Information: The library leans on ModelIO for both model loading and generation.
* Rendering: Rendering is based on Metal with MetalKit.

## 📜 Planned features
The material system is inspired by spline.design, so the goal is to make any visual appearance reproducible by the library.

| Materials  | Status            | Comment                                                                    |
|------------|-------------------|----------------------------------------------------------------------------|
| Color      | ✅ done           |                                                                            |
| Matcap     | ✅ done           |                                                                            |
| Fresnel    | 🟡 partially done | `Factor` is missing. The result doesn't match precisely with spline.design |
| Texture    | 🟡 partially done | Currently only samples based on UV                                         |
| Light      | ⚙ in progress     |                                                                            |
| Normal     | ✅ done           |                                                                            |
| Depth      | todo              |                                                                            |
| Gradient   | todo              |                                                                            |
| Noise      | todo              |                                                                            |
| Rainbow    | todo              |                                                                            |
| Outline    | todo              |                                                                            |
| Glass      | todo              |                                                                            |
| Pattern    | todo              |                                                                            |

The library provides some basic primitive shapes, but making the shape generation more advanced is not planned so far. 
The main focus will be on rendering models from files.

| Meshes     | Status            |
|------------|-------------------|
| Shape       | ✅ Done          |
| Model      | 🟡 partially done |
| ...        | todo              |

The most common post-processing effects are planned. The list is not full yet.

| Post processing | Status       |
|-----------------|--------------|
| Bloom           | todo         |
| Aberration      | todo         |
| ...             | todo         |


## 🚧 Plans for v0.3 - Provide convenient way to combine materials
- [ ] ~Scene background customization.~ (Just use `.background` of the View)
- [X] Modifiers: `offset`, `rotation`.
- [X] Modifiers: `frame` and `padding`.
- [X] Materials composition
- [X] Add materials: `fresnel`, `texture`
- [X] Blend modes: `multiply`, `screen`, `overlay`
- [ ] Add `light` material
- [ ] Animations support out of the box (Currently supported using Animatable modifier on the parent View)
- [ ] Multiple Meshes support
- [ ] Bloom effect support

## 🚧 Plans for v0.4 - Rework objects management
- [X] Split Mesh into separate types, like "ShapeMesh(), ModelMesh()"
- [ ] Add ability to apply separate materials to submeshes

```Swift
CreamyView {
    Scene(name: "my_scene.usdz") {
        Object(name: "my object") { // Define materials for the object named "my object"
            ColorMaterial(color: .white)
            LightMaterial(type: .physical) {
                DirectionalLight(direction: .init(x: 1.0, y: 1.0, z: 0.0))
            }
        }
    }
}
```

## 🚧 Plans for v0.5 - Advanced animations
- [ ] Material transition animations

## 🤔 Features under Consideration
* Clonner, which repeats Meshes. Example:

* Animated material transitions. The interface is under consideration. One option is:
```Swift
Mesh(source: .sphere) {
    Transition(.fade, value: isSwitched) { value in
        if value {
            ColorMaterial(color: .red)
        } else {
            ColorMaterial(black: .black)
        }
    }
}
```
