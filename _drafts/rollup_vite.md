# Rollup

<!-- `Graph` is essentially a director, or an orchastrator, class.
It instanciates helper classes like `PluginDriver` and `ModuleLoader` that do the work.
`inputOptions` is the [Configuration Options](https://rollupjs.org/configuration-options).
`outputOptions` is an array of outpus formats.
Each element is an instance of [`OutputOptions`](https://rollupjs.org/javascript-api/#outputoptions-object). -->
<!-- ** The build step loads only internal modules. External are ignored..?? -->
<!-- Each one of them is an output bundle, that is, a file we'll get in `build/` output folder.
** only ".js" or any extension..?
An entry module is defined by a file path?? (or just a file name??).
A module (entry or dependency module) is identified by an sting id.
** This is the file name or the path of the module..? -->
<!-- Each is identified by the module id (its file name or path?). -->
<!-- ### Preloading modules
** `ModuleLoader.fetchModule` when `isPreload` is truthy, Prloading a module is ...?
** `ModuleLoaders.preloadModule(...)` is ...?
** other calls to `ModuleLoader.fetchModule`..?
** `preloadModule` / `fetchModule` is ...? -->
<!-- ** handling a module-loading error `return error(...)`..? -->
<!-- To make sure a module is not loaded twice.
`ModuleLoader` stores a map of modules named `modulesById`.
The keys are modules ids (module id is ...?, see previous section).
The values are `Module` or `ExternalModule` instances.
`ModuleLoader` checks whether a target moudle exists in this map.
If it does, it checks whether the assertions of the stored instance
are the same as the ones created during module resolution.
It jus logs a warning-level message if it differs.
If the module does not exist in the map, then the loader creates
an `ExternalModule` instance for it and puts it in the map.
This object is created with the properties of `ResolveId`,
the outcome of the module resolution. -->
<!-- Using a `ResolvedId` instance, `ModuleLoader` fetchs the module.
`fetchModule` also looks for the module in `modulesById` map.
** `ModuleLoader.handleExistingModule` is ..?
If the module is being loaded for the first time... -->
<!-- ** `this.graph.cachedModules` are ..?
** `addModuleSource` [[/ `cachedModule.transformFiles`]] / `emitFile` ..? -->
<!-- Loading files is managed by a queue to make sure that files read/write
parallel operations are bounded.
That is, there's a defined threshold for the number of parallel files operations.
We can set manually to `maxParallelFileOps` in the configuration.
Here's the full expression for loading a file from the previous section is:
```typescript
let source: LoadResult = await this.graph.fileOperationQueue.run(
    async () => (await this.pluginDriver.hookFirst('load', [id])) ?? (await readFile(id, 'utf8'))
);
```
The queue is also used to write built files.
Although in both usages the async/await usages makes it as if the operations
are already sequential, these methods can be called by non-async functions.
The limit ensures that when many non-async methods call `preloadModule()`,
or when a plugin calls `PluginContext.load()` sequentially,
no more than the threshold number of files are being read at each moment. -->
<!-- ** `this.pluginDriver.hookParallel('moduleParsed', [module.info])` is ..?, the hook `'moduleParsed'` is ..? -->
<!-- As said obove, the plugin driver sorts plugins relatively for a given hook.
`transform` orders the plugins for the hook `'transform'`.
Then, it goes plugin by plugin.
If the plugin handles it, it'll return a transformed source.
`transform` provides the plugin driver with a function that extarcts the code string from this result.
The transformed source string is then passed to the next plugin during the next iteration.
And so on. -->
<!-- The loaded source is then handed over to the plugin that implements the `'transfrom'` hook.
The result of `transform` is an object that contains the transformed source code,
the last ast created by a
plugin during the transformation, the original source code and map,
and array of the source maps produced by the plugins during transfromation.
** AST of which language ..?
** `transfrom.ts / sourcemapChain: DecodedSourceMapOrMissing` is ..? / `decodedSourcemap` ..? -->
<!-- This attribute contains a source/assertions map.
** Assertions are ..?
** `getAssertionsFromImportExpression` is ..?
** `Module/addSource` is ..? where and why `Module/addSource` is called ..? -->
<!-- `entryModules` is the array of `Module` instances for `option.input` items.
`implicitEntryModules` is the array of `Module` instances for modules defined
in `implicitlyLoadedAfterOneOf` when a plugin hook handler calls `emitFile` with
a chunk output. They're defined by plugin authors.
`addEntryModules` loads the given modules in parallel.
** Then, builds the array of chunks `addChunkNamesToModule` ..?
The arrays of entry modules and implicit entry modules returned are sorted
according the oreder of `options.input` in the configuration object.
** `ModuleLoader.emitChunk` / `addEntryWithImplicitDependants`, or / `addEntryModules` ..?
** `Bundle/generate` / `generateChunks` / `addManualChunks` / `addAditionalModules` ..?
** `this.implicitEntryModules.delete(module)` is ..?
** `ModuleLoaders.nextChunkNamePriority` is ...? -->
<!-- "Pre"-plugins come first, then plugins without an explicit order,
and then plugins wnith the order "post".
Inside each phase, plugins ordered in the same way they're defined
in the config file.
`PluginDriver` is the class that manages the plugins.
`PluginDriver.getSortedPlugins(hookName)` orders the plugin regarding a `hookName`.
The order depends on `order` attribute of the hook-handler objects in the plugin definiton.
`hook.order` can be .
The plugin driver defines methods for parallel and for synchronous exection.
Each one iterates over them one by one, executing hook handlers.
As the name suggests, the difference is whether the plugin driver waits
for a handler to finish or not. -->
<!-- Javascript bundlers are very common in frontend projects nowadays.
Webpack remains the most widely used. But, tools that are
more fast and more easier to use are emerging.

Initially, bundlers were created to decouple development structure
from runtime structure.
We design our projects for other people to maintain.
The bundler produces artefacts the browser loads effeciently.

Due to their simple design and simple extension,
these tools expand to manage more responsibilities.
Think about templating, linting, formatting, and code analysis.

These tools themeselves don't do much.
They provide an API for plugins to do the work.
Pluigns transpile TS into JS, SCSS into CSS.
They download dependencies, they fill in build-time values, ... -->


<!-- `Bundle`, like `Graph`, is an orchastrator.
It stores the arguments it gets in the constructor and uses them to build the bundle. -->
<!-- `generated` is the `bundle` object that collects the output artefacts.
It's created by `bundle.generate()`. -->
<!-- Internally, this method first creates an empty output bundler and attaches it to the plugin driver. -->
<!-- Then, it generates the output. -->

<!-- Rollup collects the output artefacts inside a bundle.
Later the user can decide whether to write the output to the disk
or decide what else to do with it.

`bundle` is basically an object created at the beginning of the build and passed
to `FileEmitter` to collect the artefacts. Rollup augment it with more constraints,
but the core function is the same:

```typescript
const outputBundleBase: OutputBundle = Object.create(null);
``` -->
<!-- Here's how `PluginDriver.emitFile` puts an output artefact inside the bundle:
```typescript
bundle[fileName] = {
    fileName,
    name: consumedFile.name,
    needsCodeReference,
    source,
    type: 'asset'
};
```
** All output artefacts are generated by plugins..?
`emitFile` can be called from any hook other than `'outputOptions'` hook.
** why ..?
> asset file names are available starting with the renderStart hook.
> For assets that are emitted later, the file name will be available
> immediately after emitting the asset.
> -- [Rollup documentation](https://rollupjs.org/plugin-development/#this-emitfile) -->
<!-- ```typescript
// Building a graph
const graph = new Graph(inputOptions);
await graph.generateModuleGraph();
graph.sortModules();
graph.includeStatements();

// Identifying and rendering chunks
const bundle = new Bundle(outputOptions, unsetOptions, inputOptions, outputPluginDriver, graph);
const generated = await bundle.generate(isWrite);
``` -->
<!-- If [`inlineDynamicImports`](https://rollupjs.org/configuration-options/#output-inlinedynamicimports) is true,
there'll be only one output with all the modules.
If [`preserveModules`](https://rollupjs.org/configuration-options/#output-preservemodules) is truthy true,
there'll be a one output per module.
Elsewhere, [manualChunks](https://rollupjs.org/configuration-options/#output-manualchunks) is checked.
That is, if the option contains an object, the files
in the map values are loaded using `Module.loadEntryModule`,
(the same method we used to load entry modules..?).
If it's a function, then it's called with all the modules
from from the graph, and the same map is created.
Then, .. -->
<!-- `emitAsset` is called when `emittedFile` is an instance of `EmittedASset`.
It generates a unique reference id for the artefact:
```typescript
referenceId = createHash().update(referenceId).digest('hex').slice(0, 8);
```
`createHash` is a wrapper around `cryptoCreateHash('sha256')` from `node:crypto`.
`referenceId` is the asset `filename`, `name`, or a generated unique string:
```typescript
emittedAsset.fileName || emittedAsset.name || String(this.nextIdBase++)
```
Both `fileName` and `name` are optional when calling `emitFile`.
But, they're required when adding the asset to the build output.
`emitAsset` generates a `fileName` if not provided.
For the content, `EmittedAsset` instance have an optional `source` property of one of these types.
Finally, `emitAsset` puts the asset inside the bundle:
```typescript
bundle[fileName] = {
    fileName,
    name: consumedFile.name,
    needsCodeReference,
    source,
    type: 'asset'
};
``` -->
<!-- A prebuilt chunk needs to put a string inside the attribute `code`
and a string that is not a path inside the attribute `fileName`.
`emitPrebuiltChunk` validates this first, then it creates a refernce id
that will be returned, and adds an object for it to the bundle.
** difference between "pre-built chunk" and other types ..? -->
<!-- In the constructor, a chunk initilazes extracts the entry modules,
implicit entry modules, dynamic entry modules, and exports
(** what are those ..? explain ..?)
from the modules it's responsible for.
** Inside its constructor ..?
** `Chunk.orderedModules` ..? with whih order ..? -->
<!-- `Chunk.render` has no side-effects. It returns an instance of `ChunkRenderResult`:
```typescript
interface ChunkRenderResult {
  chunk: Chunk;
  magicString: MagicStringBundle;
  preliminaryFileName: PreliminaryFileName;
  preliminarySourcemapFileName: PreliminaryFileName | null;
  usedModules: Module[];
}
```
** `preliminaryFileName` is ..?
** `preliminarySourcemapFileName` is ..?
** usages of fields..?
`usedModules` contains the list of non-empty modules the chunk will contain.
** usages? -->

# Vite

<!-- These are the main middlewares:
```typescript
// main transform middleware
middlewares.use(transformMiddleware(server))
// serve static files
middlewares.use(serveRawFsMiddleware(server))
middlewares.use(serveStaticMiddleware(server))
if (config.appType === 'spa' || config.appType === 'mpa') {
  // html fallback
  middlewares.use(htmlFallbackMiddleware(root, config.appType === 'spa'))
  // transform index.html
  middlewares.use(indexHtmlMiddleware(root, server))
}
``` -->
<!-- `serveRawFsMiddleware` handles requests to filesystem resources.
`serveStaticMiddleware` handles project static files, its doc says:
```typescript
// only serve the file if it's not an html request or ends with `/`
// so that html requests can fallthrough to our html middleware for
// special processing
```
It, also, is based on a serv instance that poitns to the server root:
```typescript
const serve = sirv(server.config.root, sirvOptions({ getHeaders: () => server.config.server.headers }))
``` -->
<!-- [appType](https://vitejs.dev/config/shared-options.html#apptype) is a configuration option.
when its `'spa'` or `'mpa'`, then Vite is not executed in a middleware
mode and no ssr logic is needed.
In such case, html files are handled by `htmlFallbackMiddleware`, and `indexHtmlMiddleware` middlewares
before sending them back. -->
<!-- ```typescript
const assetAttrsConfig = {
  link: ['href'],
  video: ['src', 'poster'],
  source: ['src', 'srcset'],
  img: ['src', 'srcset'],
  image: ['xlink:href', 'href'],
  use: ['xlink:href', 'href'],
}
```
It overwrites the values of these attributes in these elements into pathes
that start with the server url:
```typescript
// rewrite `./index.js` -> `localhost:5173/a/index.js`.
// rewrite `../index.js` -> `localhost:5173/index.js`.
// rewrite `relative/index.js` -> `localhost:5173/a/relative/index.js`.
``` -->


<!-- For a `<script>` element, first, the node attributes are check to find
the source path, and whether `type` is `'module'`, and whether the script is `async`.
If the loaded source is public:
`<script src="${url}"> in "${publicPath}" can't be bundled without type="module" attribute`
```typescript
const url = src && src.value
const isPublicFile = !!(url && checkPublicFile(url, config))
if (isPublicFile) {
  // referencing public dir url, prefix with base
  overwriteAttrValue(
    s,
    sourceCodeLocation!,
    toOutputPublicFilePath(url),
  )
}
```
** explain this..?
If the `<script>` element has `type='module'`,
Vite marks the tag for removal,
sets `everyScriptIsAsync`, `someScriptsAreAsync`, and `someScriptsAreDefer`,
and adds an `import` statement to the `js` string.
It adds `\nimport ${JSON.stringify(url)}` if `url && !isExcludedUrl(url) && !isPublicFile`. (`<script type="module" src="..."/>`)
It adds `\nimport "${id}?html-proxy&index=${inlineModuleIndex}.js"` if
```typescript
// <s"cript type="module">...</script>
const filePath = id.replace(normalizePath(config.root), '')
addToHTMLProxyCache(config, filePath, inlineModuleIndex, {
  code: contents,
})"
```
** explain this..?
To do this, it uses [strip-literal](https://www.npmjs.com/package/strip-literal)
to replace comments with spaces,
to avoid matching urls in comments and to use indexes from the cleaned string
in the original one. -->
<!-- ### CSS/JS transfromation -->
<!-- ```typescript
const result = await transformRequest(url, server, { html: req.headers.accept?.includes('text/html') })
// ...
const depsOptimizer = getDepsOptimizer(server.config, false) // non-ssr
const type = isDirectCSSRequest(url) ? 'css' : 'js'
const isDep = DEP_VERSION_RE.test(url) || depsOptimizer?.isOptimizedDepUrl(url)
```
** explain this ..? -->
