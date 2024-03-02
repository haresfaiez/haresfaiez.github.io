---
layout:   post
comments: true
title:    "Vite dev mode overview"
date:     2024-02-10 12:02:00 +0100
tags:     featured
---

> At the very basic level, developing using Vite is not that different from
> using a static file server. However, Vite provides many enhancements over
> native ESM imports to support various features that are typically seen
> in bundler-based setups.
>
> -- [Vite guide, Features](https://vitejs.dev/guide/features.html)

[Vite dev mode](https://vitejs.dev/guide/features.html) leverages [ES modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules)
widespread support, augments it with a Rollup-like [plugin system](https://vitejs.dev/guide/api-plugin), and implements a similar [hook](https://vitejs.dev/guide/api-plugin#vite-specific-hooks) triggering system
and a module graph structure.
The result is an environment that offers short feedback cycles for developers to test-drive their code.

The library starts a development server and a web socket server when we run `vite` from the command line.

The dev server is a [primitive Nodejs server](https://nodejs.org/api/http2.html) that hosts the application:

```typescript
const { createSecureServer } = await import('node:http2')
return createSecureServer(httpsOptions, app)
```

Vite creates an instance of [connect](https://www.npmjs.com/package/connect)
and attaches it to the web server.
That allows the library to inject middlewares to edit HTML pages before
returning them to the browser.

Static, non-HTML, files are handled by a
[sirv](https://github.com/lukeed/sirv/tree/master/packages/sirv)-based middleware.

HTML pages are handled by a middleware that executes hook handlers from the defined [plugins](https://vitejs.dev/guide/api-plugin).

The web socket server is an instance of [ws](https://www.npmjs.com/package/ws).
It handles the messaging between the dev server and the browser:

```typescript
import { WebSocketServer } from 'ws'
import type { WebSocket } from 'ws'
// ...
const customListeners = new Map<string, Set<WebSocketCustomListener<any>>>()
const clientsMap = new WeakMap<WebSocket, WebSocketClient>()
wss = new WebSocketServer({ noServer: true })
```

This is the basis of Vite [Hot Module Replacement](https://vitejs.dev/guide/api-hmr).
`customListeners` maps each event to a set of its handlers.
`clientsMap` contains the connected sockets.
One of the clients is the opened HTML page inside the browser.

## HTML transformation

If you try to inspect an HTML page built by Vite,
you will see a timestamp at the end of script URLs.
You might also find different URLs than those you have in the source file.
And you'll find the source code responsible for HMR injected in the beginning.

Vite keeps track of what can be changed without a page reload.

It captures:
  * Javascript `<script>` elements
  * Inline CSS code inside `style` attributes
  * `<style>` elements
  * Links to CSS files
  * References to Javascript modules.

Vite maintains a module graph quite similar to
[Rollup module graph](/2023/11/26/Rollup-main-components.html#building-module-graph)
and handles each of these as a separate module,
that is, a distinct node.

The main attributes of `ModuleGraph` are:

```typescript
  urlToModuleMap = new Map<string, ModuleNode>()
  idToModuleMap = new Map<string, ModuleNode>()
  // a single file may correspond to multiple modules with different queries
  fileToModulesMap = new Map<string, Set<ModuleNode>>()
```

`ModuleNode` is a graph node.

`urlToModuleMap` and `idToModuleMap` have the same values.

The first map keys are the URLs used for importing.

The second map keys are the resolved `id`s for these URLs.
These are usually files on the file system.

This is how an `id` returned from `ResolveId` hook is transformed into a file name:

```typescript
url.replace(/[?#].*$/s, '')
```

`fileToModulesMap` maps a file name, the result of this latter expression,
to the modules inside it.

From a certain point of view, Vite inserts a layer between the HTML and the modules.
In some cases, the layer is transparent.
The initial code is kept but slightly modified.
In other cases, a [proxy](https://en.wikipedia.org/wiki/Proxy_pattern)
is inserted between the import and the imported.

To identify the modules,
Vite creates a [`MagicString`](https://www.npmjs.com/package/magic-string) instance with the initial HTML string.
It traverses the HTML with a depth-first approach using [parse5](https://www.npmjs.com/package/parse5).
It looks for `<script>` or `<style>` elements,
elements with an inline `style` attribute that contains
[`url()`](https://developer.mozilla.org/en-US/docs/Web/CSS/url)
or [`image-set()`](https://developer.mozilla.org/en-US/docs/Web/CSS/image/image-set),
and elements with some attributes that contain URLs,
that is, elements with `href` and `src` attributes.

Let's start with styles modules.

The `id` of an inline style module is:

```typescript
const url = `${proxyModulePath}?html-proxy&inline-css&style-attr&index=${index}.css`
```

For a `<style>` element, it's:

```typescript
const url = `${proxyModulePath}?html-proxy&direct&index=${index}.css`
```

`proxyModulePath` is the host HTML file.
`index` is the order of the URL inside that file.

The module content is returned by the styles plugins.
`CssPlugin` and `CssPostPlugin` implement `transform` hook handlers for
modules whose `id` ends with:

```typescript
'css',  'less',  'sass',  'scss',  'styl',  'stylus',  'pcss',  'postcss',
```

We can manually add plugins and define hook handlers that handle such modules as well.

Vite runs, first, `CssPlugin` to compile the styles into CSS.

`CssPostPlugin` then executes a list of [postcss](https://postcss.org/) plugins
to interpret [CSS modules](https://github.com/css-modules/css-modules).

It uses [postcss-import](https://www.npmjs.com/package/postcss-import)
to inline `@import` calls
and keeps track of the [imported modules](https://www.npmjs.com/package/postcss-import#dependency-message-support)
and their transitive dependencies in the module graph.

Other than this, CSS code is mostly intact in the HTML source.

Handling `<script>` elements is more-or-less the same.

Three types of scripts exist:

* Scripts with `type = 'module'` and a Javascript body
* Scripts with an `src` attribute
* Scripts with a Javascript body

In all cases, a module node is added to the module graph.

In the first case though, Vite replaces the script with a script/src element:

```typescript
const modulePath = `${proxyModuleUrl}?html-proxy&index=${inlineModuleIndex}.js`
s.update(start, end, `<script type="module" src="${modulePath}"></script>`)
```

`proxyModuleUrl` is url of the container HTML file.
`inlineModuleIndex` is the order of the inline-module in the file.

The identification of Javascript dependencies and their transitive dependencies
will be handled at the end, just before sending the Javascript source to the browser, by an analysis plugin.
This latter uses [es-module-lexer](https://github.com/guybedford/es-module-lexer) to identify imports,
analyze them, and rewrite them to their respective modules ids.

## Hot Module Replacement

Vite instantiates a [chokidar](https://www.npmjs.com/package/chokidar) instance to watch file system changes.

In the browser, it inserts a client script inside the `<head>` element of the HTML file:

```html
<script type="module" src="/@vite/client"></script>
```

This script keeps track of `import.meta.hot.accept()` calls (with `deps` and `callback`, or with only a `callback`) inside a map named `hotModulesMap`:

```typescript
interface HotModule {
  id: string
  callbacks: {
    deps: string[]
    fn: (modules: Array<ModuleNamespace | undefined>) => void
  }[]
}
```

If the source accesses [HMR API](https://vitejs.dev/guide/api-hmr.html#hmr-api),
that is, if the code contains `import.meta.hot`,
Vite adds HMR initialization:

```typescript
str().prepend(
  `import { createHotContext as __vite__createHotContext } from "${clientPublicPath}";` +
  `import.meta.hot = __vite__createHotContext(${JSON.stringify(normalizeHmrUrl(importerModule.url))});`,
)
```

`createHotContext` defines the `accept()` method.

A module `A` "accepts" another module `B` when `A` can apply any update to `B`
in the web page, without reloading.

A module is "accepted" when it's marked as to be replaced.
A module is "self-accepting" when it accepts its own updates.

A module calls [`import.meta.hot.accept(callback)`](https://vitejs.dev/guide/api-hmr#hot-accept-cb)
to handle its updates.
The `callback` will be called with the updated code each time the module changes.

It calls [`import.meta.hot.accept(deps, callback)`](https://vitejs.dev/guide/api-hmr#hot-accept-deps-cb)
to handle the updates of some or all its dependencies.

Each module node in the modules graph keeps track of its importers, the modules it accepts, and whether it's self-accepting.

When a file changes, Vite locates the affected modules and identifies the update boundary.
This lookup is called "Update propagation".
Vite iterates over the module importers
and adds a boundary when an importer has the child in its accepted HMR dependencies.

This minimizes and focuses the updates.
Only updates for a boundary are sent to the browser.

The two main types of messages the web socket server sends to the client script are `'update'` and `'full-reload'`.

After getting a message of the latter type, the frontend handler simply calls
[`location.reload()`](https://developer.mozilla.org/en-US/docs/Web/API/Location/reload).

When it gets an update message, it identifies the target module and updates it.

The update message interface is:

```typescript
interface Update {
  type: 'js-update' | 'css-update'
  path: string
  acceptedPath: string
  timestamp: number
  explicitImportRequired?: boolean | undefined
}
```

`path` is the `id` of the target module that'll get the update.
`acceptedPath` is the `id` of the actual changed module.

A CSS update is sent "when a CSS file referenced with `<link>` is updated".
The client script then searches for a `<link>` element whose `href` is the update path
and rewrites it.

Here's how the link tag is replaced:

```typescript
const newLinkTag = el.cloneNode()
newLinkTag.href = new URL(newPath, el.href).href
newLinkTag.addEventListener('load', () => el.remove())
el.after(newLinkTag)
```

If an "accepted" Javascript module is modified. A `'js-update'` message is sent.
The script then imports the updated module with a timestamp attribute at the end of the URL:

```typescript
fetchedModule = await import(update.acceptedPath + `?t=${update.timestamp}`)
```

Then, it passes the updated code to the callbacks associated with the module inside `hotModulesMap`.
