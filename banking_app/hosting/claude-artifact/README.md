# Hosting the web build as a Claude artifact

`index.html` is the page shell used to publish `flutter build web --release --no-web-resources-cdn` as a private claude.ai artifact.

- It loads `flutter.js` and `main.dart.js` from files published beside it, and points Flutter's emoji/symbol fonts at a local `fallback-fonts/` copy, because the artifact frame blocks Google's CDNs.
- **Saving:** browser storage on a hosted artifact isn't kept reliably between visits. Before the app starts, the shell restores the app's `shared_preferences` keys (`flutter.*`) from the artifact's private per-viewer database (`db` capability, `data/users/<viewer>/horizon-bank`, gzip + base64). After that it mirrors every change back, debounced. Publish with `capabilities: {"db": {}, "user": {}}`.
- Off claude.ai (`window.claude` absent) it behaves like a normal Flutter web page: data stays in localStorage.
- No Dart code knows about this; the app still just uses `shared_preferences`.
