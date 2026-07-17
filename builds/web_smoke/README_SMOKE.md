# Web Smoke Build

Export from the Godot `Web Test` preset to this directory:

```text
builds/web_smoke/index.html
```

Upload the whole directory contents. Required runtime files:

```text
index.html
index.js
index.wasm
index.pck
```

Optional generated files may include:

```text
index.audio.worklet.js
index.worker.js
favicon.png
```

Required MIME types:

```text
.wasm -> application/wasm
.pck  -> application/octet-stream
.js   -> application/javascript
.html -> text/html
.png  -> image/png
.jpg  -> image/jpeg
```

Smoke result template:

```text
URL:
Device:
Browser:
Can enter game:
Can merge:
Projectile colors correct:
Hit effects correct:
Layering correct:
Console errors:
Screenshot:
```
