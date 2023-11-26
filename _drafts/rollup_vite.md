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
<!-- The main difference in represation is that while a static import
is identified by a source, that is the imported path,
the dynamic import is identified with a structure: -->
<!-- ```typescript
export interface DynamicImport {
  argument: string | ExpressionNode;
  id: string | null;
  node: ImportExpression;
  resolution: Module | ExternalModule | string | null;
}
```
** explain this ..? fields usages..? and why do we need other fields than `id`..?
** why can `resolveId` be a string or a null value ind DynamicDependency type ..? `resolvedId: ResolvedId | string | null` ..? -->

<!-- It's `true` if the given module is Rollup cannot locate it through its normal procdure.
It's not handled by [`options.external`](https://rollupjs.org/configuration-options/#external),
no plugins handle its resolution hook,
and its id is not an absolute path.
** Usually, the name is an alias or an external package..?
It's also true if it's id, it's file name is not absolvute
[`makeabsoluteexternalsrelative`](https://rollupjs.org/configuration-options/#makeabsoluteexternalsrelative)
can force it to be `true` if the file is absolute here.
** explain this in simple terms...?
`external` can be `true` also if
a plugin handles it and returns an object with `external` value is `'relative'`,
or the file id (the string used to import it) is not absolute,
or the plugin returns `true` as `external` value and `makeabsoluteexternalsrelative` makes it external.
In the last two situation, `external` will be `'absolute'` if it's not `true`. -->
<!-- ** Sorting the modules in `addEntryModules` ..?
** `graph.sortModules()` is ...? -->
<!-- Then,
```typescript
module.linkImports();
```
** explain this..? -->

<!-- ## Tree shaking

`moduleSideEffects` inside `ResolvedId` structure is `true` by default unless a value for
[`options.treeshake.moduleSideEffects`](https://rollupjs.org/configuration-options/#treeshake) is provided.
The option is part of the structure that prescribe tree-shaking.
It can be set to a function that returns a boolean.
`moduSideEffects` for a module can be set to `'no-treeshake'` using
plugins. A plugin can handle [the hook `'resolveId'`](https://rollupjs.org/plugin-development/#resolveid)
and return a `ResolveId` structure,
or also [the transform hook](https://rollupjs.org/plugin-development/#transform).
** usages and implications of `moduleSideEffects` ..?

`graph.includeStatements()` marks the code to be a part of the output bundle.
** `Module.isIncluded` is ..?
** `Module.include*` methods ..?
** usages of `Module/*.included`/`Module/*.isIncluded` ..?

Each moudle should be included once. `Module.isExecuted` is `true`.
when a module is included, its internal modules dependecies, that is:
```typescript
!(dependency instanceof ExternalModule)
    && (dependency.info.moduleSideEffects || module.implicitlyLoadedBefore.has(dependency))
```
** why are we excluding `ExternalModule` ..?

`info.moduleSideEffects` takes its value from module's `ResolvedId` we talked about above.
The internals of this method depends on the [tree shaking option](https://rollupjs.org/configuration-options/#treeshake).
If such value is false, all modules are included:

```typescript
for (const module of this.modules) module.includeAllInBundle();
```

If it's truthy, Rollup goes over the order modules list once or twice.
The second pass is done if `module.preserveSignature !== false`.
** `module.preserveSignature` is ..?

There are two ways to include a module:

```typescript
if (module.info.moduleSideEffects === 'no-treeshake') {
  module.includeAllInBundle();
} else {
  module.include();
}
```

`includeAllInBundle` marks the whole module to be inside the output bundle.
It goes over all the module AST nodes and sets `this.included` to `true`.
** other responsibilities of `Node.include()` ..? In the process also, it ..?

** It then calls `includeAllExports()` ..?

** `this.graph.needsTreeshakingPass = true` is ..?

** `include()` ..?

After the first pass:

```typescript
// We only include exports after the first pass to avoid issues with
// the TDZ detection logic
module.includeAllExports(false);
this.needsTreeshakingPass = true;
```
** explain this ..? -->

<!-- The value returned by `emitAsset`, and thus `emitFile`, is the reference id string.
Later hook handlers can access the asset name using `getFileName(referenceId)`.
** is the referenceId stored somewhere so that other plugins find it ..?
`getFileName` is part of the API Rollup provides to the plugins. -->
<!-- `chunk.generateFacades()` returns an array of `Chunk` instances for each chunk.
** They're called "facades" because ..?
These arrays are added to the array of chunks created previously.
That is, the list of all chunks(** all..?) is composed from the manually
created chunks (using manualChunks option) and the arrays of facades for each
of these chunks.
To do so, the method collects the list of exposed variables.
Such array is composed from the namespaces of the dynamic entry modules
and the modules exported (how a module export a modul...?) by entry modules (normal and implicit)
that should be in the current chunk.
** The namespace of a module is.. ? (a variable that contains all the exports of that module ..?)
It's an AST node instance:
A new `NamespaceVariable` is created and attached to each module when attaching
its source.
```typescript
export default class NamespaceVariable extends Variable {
```
Being a variable, a namespace has an `included` attribute.
It's included (meaning all the module exports are included) when
a module is imported with `*`, like in:
```typescript
import * from `./utils`
```
It's included by the module containing this statement, when the import statement is included.
Thus, it's included when a parent module is itself is included with a wildcard,
** and when: `*includeAllExports*` (if `this.exports` or `this.getReexports()`), `includeDynamicImport` (if !`importedNames`)
A namespace can also references merged namespaces, these are the namespaces
of the modules imported with the wildcard.
These are merged and included when:
** `includeExportsByNames` (if `name` not in exports/reexports), `*includeAllExports*` (`includeNamespaceMembers`)
** and `deoptimizePath` ..?
** exported variables are created by `getExportNamesByVariable` ..?
The list of facades that'll be returned is built from the list of chunks of each entry module (normal and implicit).
For each module, the latter is an aggregation of modules names and of file names.
It's created by extracting the names from both `chunkNames` and `chunkFileNames`.
** creation and usages of `module.chunkNames` ..?
** creation and usages of `module.chunkFileNames` ..?
A new `Chunk` instance is created for each chunk name/filename, for each module.
** Difference between create `Chunk` normally and create `Chunk` for facades using `generateFacade` ..?
** `if (!this.facadeModule) {` is ..?
** Then, for dynamic entry modules..?
** `addNecessaryImportsForFacades` is ..?
** `module.preserveSignature` is ..? its usages..? -->
<!-- ** `Module.resolvedIds` contains a map of ??/`ResolvedId` of the dependencies??.
** is every has a module per specifier..? multiple resolveId for each module..? `module.resolvedIds[specifier]` is ..?
***********************--------------**************************************
In addition to the files specified inside the `input` configuration option,
there are implicitly added entry modules.
These are treated as entry modules. They are checked during tree-shanking.
* are they included separately in the bundle..?
* An implicit entry module is ...? is it an entry module..?
* usages of `this.implicitEntryModules` .. in `Graph` ..?
* The distinction between an entry module and an implicit entry module is ..?
* usages of `implicitEntryModules` ..?
* other calls to `ModuleLoader.loadEntryModule`..?
** `emitChunk` ..
  `EmittedChunk` has a property named `implicitlyLoadedAfterOneOf`.
  It's optional. It might contain an arry of file names that import the module
  described by the chunk.
  If that property is `undefined`, the chunk is treated exactly as an entry module.
  If it's there, the module might not be an entry module.
  Only when it's explicity mentioned in `options.input` that it's handeled as a normal entry module.
  Otherwise, it's handeled a an "implicit entry module".
  The module that depends on it are immediately imported.
***********************--------------************************************** -->

<!-- ***********************--------------**************************************
For each module, it
```typescript
this.setDynamicImportResolutions(fileName);
this.setImportMetaResolutions(fileName);
this.setIdentifierRenderResolutions();
```
** explain this..?
** `Module.includedDynamicImporters` and its usages in `Chunk.ts` ..?
***********************--------------************************************** -->

<!-- Then it adds a module to the rendered modules, that is a final list
of modules that should be in the chunk, only if:
```typescript
module.isIncluded() || includedNamespaces.has(module)
```
** explain this..? -->

<!-- Then `module.render` is called.
This method copies the module string, then
** `Program.render` is ...?

It returns an object:

```typescript
{ source: MagicString; usesTopLevelAwait: boolean }
```

** `source` contains ..?
** `usesTopLevelAwait` is `true` when ..? -->

<!-- The source is added to the bundle using magic-string's `Bundle.addSource`,
which simple adds the modlue source and filename to the bundle. -->

<!-- `usesTopLevelAwait` is used to check whether any of the modules handleed by the chunk
has a top-level `await`.
** The result is returned and used to ..? -->
<!-- In addition to putting each module source into one string,
`Chunk` also inspects accesses to global variables.
As the output is one code string per chunk, chunk rendring
builds a set `accessedGlobals` fro the global varibales accessed
by all the modules inside the chunk.
** `this.accessedGlobalsByScope` A map is created early in the rendering process that maps ...? -->

<!-- Also, for each module whose namespace is included,
that is, a module that's imported with a wildcard,
a module definition string is created.
Such string is in the form:
```typescript
const moduleName =
```
** Complete from `NamespaceVariable.renderBlock`..?

If such module should be exported from the chunk itself,
a code denoting an export call for the module is added to this string:

```typescript
const ...
exports()...
```
** Complete from previous snippet..? and from `getSystemExportStatement`..?

The output string is either added to the beginning of the chunk magic string
or just after the module source.
** It's added at the beginning if `module.namespace.renderFirst()` -->
<!-- 
The second parameters contains, among many booleans, the list of the chunk dependencies.
This is a list of `ChunkDependency` instance.
** Each element is created from a `Chunk` or an `ExternalChunk` instance ..?
** `ExternalChunk.imports` contains ..?
And it contains the list of the chunk exports.
** `getChunkExportDeclarations()` is ..? -->
<!-- A dynamic dependency is added to `module.dynamicDependencies`
and the importing module is added the the dependency `dependency.dynamicImporters`.
Static dependencies are added to `module.dependencies` and the importer's `dependency.`importers` are updated.
This is how the links in the graph are created. -->

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
