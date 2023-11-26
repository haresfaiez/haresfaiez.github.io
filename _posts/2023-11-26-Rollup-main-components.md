---
layout:   post
comments: true
title:    "Rollup main components"
date:     2023-11-26 12:02:00 +0100
tags:     featured
---

> Rollup is a module bundler for JavaScript which compiles small pieces of code
> into something larger and more complex, such as a library or application.
> Rollup can optimize ES modules for faster native loading in modern browsers,
> or output a legacy module format allowing ES module workflows today.
>
> [Rollup](https://github.com/rollup/rollup)

Whether used through the Javascript API or the command line,
Rollup build steps are the same.

## Building module graph

Rollup build starts by creating a module graph.
This graph contains the entry files and their dependencies.
It'll be used to analyze the dependencies,
find the exported expressions from the output bundle,
run effective tree-shaking, and optimize the output bundle.

The heads of the module graph we end up with are the entry modules.
These are the modules defined in the [`input`](https://rollupjs.org/configuration-options/#input)
option of the configuration.
Each graph node is created by first resolving a module file name
then by fetching its source, parsing it, fetching its dependencies, and adding it to the graph.

When resolving a module, `ModuleLoader` looks for a plugin that handles
the hook `'resolveDynamicImport'` or the hook `'resolveId'`.
When no plugin does,
it looks for a file whose path is the given id.
If not found, it attempts to add `.mjs` to the add.
If also not found, it tries to add `.js`.

There are two resolution hooks because a module dependency can be static or dynamic.
A static dependency is an import statement:

```typescript
import { a } from './b'
export * from './other' // import is implicit here
export { name } from './other' // same here, import is implicit
```

A dynamic dependency is an import expression:

```typescript
import('bar')
```

Hooks augment the build process.
A [hook](https://rollupjs.org/plugin-development/#build-hooks)
is a step in the build process where plugins extend the core logic.
A plugin handles a hook by defining a function that takes a module
id (its filename) and optionally a context object.
It returns either the handling result or an `undefined` value if it's
not responsible for the given module.

The outcome of the resolution step is an instance of `ResolvedId`.
Such an object is the core of a graph node.
It's used to create a `Module` or a `ExternalModule` instance that'll be inserted into the graph:

```typescript
interface ResolvedId {
  assertions: Record<string, string>;
  meta: CustomPluginOptions;
  moduleSideEffects: boolean | 'no-treeshake';
  syntheticNamedExports: boolean | string;
  external: boolean | 'absolute';
  id: string;
  resolvedBy: string;
}
```

A module is internal if a plugin handles it and marks it as implicit,
by setting `external` to `false` in the returned `ResolveId` instance, or
if the module id references an existing file.

A module, otherwise, is considered external.
External modules are the ones that should be kept out of the output bundle.

As `external` type says, external modules are not all the same.
`external` is either `true` or `'absolute'`.
If the external filename is not absolute,
the file name will be changed to a path relative to the current project.
An absolute one always references an existing file on the file system with an absolute path.
That one will be kept as it is in the final bundle.

The created `Module` instance contains the module source code as a string.
Setting the source is named "loading".

Given a module, Rollup checks whether a plugin handles it inside a `'load'` hook.
If no plugin does, the library reads the file with
[readFile](https://nodejs.org/dist/latest-v6.x/docs/api/fs.html#fs_fs_readfile_file_options_callback):

```typescript
(await this.pluginDriver.hookFirst('load', [id])) ?? (await readFile(id, 'utf8'))
```

The outcome of the loading step is a `SourceDescription` instance:

```typescript
interface SourceDescription extends Partial<PartialNull<ModuleOptions>> {
  ast?: AcornNode;
  code: string;
  map?: SourceMapInput;
}
```

The AST is either returned from the `'load'` hook handler,
or it's locally created after the source is fetched, just before attaching it
to the `Module` instance.
You can read more about Acorn AST [here](/2020/06/28/acornjs-internals-main-concepts.html).

The dependencies of a module are collected during the creation of the AST.
Static dependencies are stored inside `Module.sourcesWithAssertions`.
Dynamic dependencies are stored inside `Module.dynamicImports`.
Inside the constructor of an Acorn `import` or `export` node,
the object adds itself to one of the two lists.

Fetching the dependencies is then done in two steps: resolution and fetching.
During the resolution step, every entry from the two lists is transformed into
a `ResolveId` instance, then into a `Module` or an `ExternalModule` instance.
During the fetching step, its content is attached.
At the end, the dependencies are attached to the importing module.

## Identifying chunks

You can learn about output generation and its hooks in the
[documentation](https://rollupjs.org/plugin-development/#output-generation-hooks).

The main output of Rollup is a bundle object.
This bundle contains a map whose entries are output units.
Usually, these are the files we get inside the build output directory.

The bundle is defined as:

```typescript
interface OutputBundle {
  [fileName: string]: OutputAsset | OutputChunk;
}
```

The difference between an "asset" and a "chunk" is that an asset is added to the output
bundle while a "chunk" is a Javascript filename that's added as an entry module.
Adding the latter triggers the process of resolution,
loading, dependencies fetching, and augmenting the module graph.

Hook handlers call [`emitFile`](https://rollupjs.org/plugin-development/#this-emitfile)
to add a chunk or an asset to the bundle.

The build process identifies the output units and renders them inside a bundle entry.
Such output units are named "chunks".
Many scenarios are possible. Depending on the output values, we might
have one chunk for all the modules, or we might need many.

The identification is explained in the
[comment](https://github.com/rollup/rollup/blob/master/src/utils/chunkAssignment.ts)
at the beginning of `chunkAssignment.ts`.

After getting the list of chunk names and their subject modules, Rollup
creates `Chunk` instances for output units, builds a chunk graph.
Then it analyzes the modules to find out chunk exports, imports, and re-exports.

To build the chunk graph, Rollup iterates over each chunk modules,
gets their dependencies and their transitive
dependencies using a depth-first traversal of the module graph,
and then adds the chunks of these dependencies as dependencies
to the subject chunk.

`Chunk.dependencies` in the end will contain instances of `Chunk` and `ExternalChunk`.
(for external modules).

## Rendering chunks

The last step of the build is rendering the chunks.
Rollup builds a string for each chunk and puts it inside the bundle.

The library creates a [magic-string](https://www.npmjs.com/package/magic-string) instance.
It goes over the modules one by one and adds them to this string.
Then, it uses a format-aware finalizer to create the final string.

Rollup exports a constant list of [finalizers](https://github.com/rollup/rollup/tree/master/src/finalisers):

```typescript
export default { amd, cjs, es, iife, system, umd };
```

Each of these is a function that takes a magic string
(the outcome of rendering a chunk), a set of options that describe
the chunk rendering context, and the output options object.
It modifies the given magic string and makes it confirming.

`es` finalizer for example adds an import block at the beginning and an export block at the end.
To build the export block, the module iterates over the export expressions
passed inside the rendering options object
(These are Acorn export nodes that are collected from the chunk modules)
and builds one `export` statement.
Same for the import block, it iterates over the dependencies.
For each dependency, it adds an `import` or an `export ... from ...` statement for
the values imported and reexported from the modules.

## Writing the output

> The rollup.rollup function receives an input options object and returns a bundle object.
> On a bundle object, you can call bundle.generate multiple times with different output
> options objects to generate different bundles in-memory.
> If you directly want to write them to disk, use bundle.write instead.
>
> [JavaScript API](https://rollupjs.org/javascript-api/)

This is the code that writes the generated bundle to the file system:

```typescript
await Promise.all(
  Object.values(generated).map(chunk =>
    graph.fileOperationQueue.run(() => writeOutputFile(chunk, outputOptions))
  )
);
```

Rollup persists each file using `writeOutputFile`.
Internally this function uses [`mkdir`](https://nodejs.org/api/fs.html#fspromisesmkdirpath-options)
and [`writeFile`](https://nodejs.org/api/fs.html#filehandlewritefiledata-options) native functions
to write the files.
