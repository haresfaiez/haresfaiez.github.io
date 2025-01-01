## Creating Document and Frames/LocalFrame for testing
`dummy_page_holder_` is created during test setup, that is, inside `PageTestBase::SetUp`.
It's an instance of `DummyPageHolder`:

```cpp
// Creates a dummy Page, LocalFrame, and LocalFrameView whose clients are all
// no-op.
//
// This class can be used when you write unit tests for components which do not
// work correctly without layoutObjects.  To make sure the layoutObjects are
// created, you need to call |frameView().layout()| after you add nodes into
// |document()|.
```
> with "no-op" clients, it means that the rendering operations of this view will not actually do anything.

`frame_` is initialized in the constructor:

```cpp
chrome_client = &GetStaticEmptyChromeClientInstance();

page_ = Page::CreateNonOrdinary(*chrome_client, *agent_group_scheduler_);

frame_ = MakeGarbageCollected<LocalFrame>( // ...
frame_->SetView(MakeGarbageCollected<LocalFrameView>(*frame_, initial_view_size));
frame_->Init(
```

An empty chrome client, that is an instance of `EmptyChromeClient`:
```cpp
chrome_client = &GetStaticEmptyChromeClientInstance();
```
** explain this..?

A non-ordinary page, a `Page` instance is:
```cpp
// A Page roughly corresponds to a tab or popup window in a browser. It owns a
// tree of frames (a blink::FrameTree). The root frame is called the main frame.
```

It's created by:
```cpp
Page* Page::CreateNonOrdinary(ChromeClient& chrome_client,
                              AgentGroupScheduler& agent_group_scheduler) {
  return MakeGarbageCollected<Page>(
      base::PassKey<Page>(), chrome_client, agent_group_scheduler,
      BrowsingContextGroupInfo::CreateUnique(), /*is_ordinary=*/false);
}
```
** explain this ..?
** what's `agent_group_scheduler` ..? created in `DummyPageHolder`.. by `agent_group_scheduler_` ..?

`frame_` is an instance of `LocalFrame`:
```cpp
// A LocalFrame is a frame hosted inside this process.
```

A frame view is attached to this frame using `SetView`.
An instance of `LocalFrameView` is created and passed.
** explain `LocalFrameView` constructor ..?

Then, then frame is initialized with `frame_->Init`:
```cpp
  // Initialize the LocalFrame, creating and initializing its LocalDOMWindow. It
  // starts from the initial empty document.
```

Internally, this method essentially contains:
```cpp
CoreInitializer::GetInstance().InitLocalFrame(*this);
// ...
loader_.Init(document_token, std::move(policy_container), storage_key, document_ukm_source_id, creator_base_url);
```

`CoreInitializer::GetInstance()` returns an instance of `CoreInitializer`.
** why is it a singleton..? its usages..?

That class defines `InitLocalFrame`:
```cpp
// Methods defined in CoreInitializer and implemented by ModulesInitializer to
// bypass the inverted dependency from core/ to modules/.
// Mojo Interfaces registered with LocalFrame
virtual void InitLocalFrame(LocalFrame&) const = 0;
```
** explain this..? where is it implemented..?

`loader_`is created by `LocalFrame` constructor:
```cpp
_loader(this)
```

It's an instance of `FrameLoader`.
** explain `FrameLoader.init`..?

Getting the document later during the test execution returns the initialized document:
```cpp
*frame_->DomWindow()->document()
```
** explain this..?

`DomWindow()` is a getter for the attribute named `dom_window_`.
It's defined inside `Frame`:

```cpp
Member<DOMWindow> dom_window_;
```
Keep in mind that `LocalFrame` extends `Frame`.

`DomWindow` is:

```cpp
// DOMWindow is an abstract class of Window interface implementations.
// We have two derived implementation classes;  LocalDOMWindow and
// RemoteDOMWindow.
```

This is initilizad by `LocalFrame.Init`, the doc there says
`Initialize the LocalFrame, creating and initializing its LocalDOMWindow.`
It's a `LocalDOMWindow` instance.
** Where is `dom_window_` assigned/set ..?

We have:
`DOMWindow < WindowProperties < EventTarget < ScriptWrappable`

`ScriptWrappable` is:
```cpp
// ScriptWrappable provides a way to map from/to C++ DOM implementation to/from
// JavaScript object (platform object).  ToV8() converts a ScriptWrappable to
// a v8::Object and toScriptWrappable() converts a v8::Object back to
// a ScriptWrappable.  v8::Object as platform object is called "wrapper object".
// The wrapper object for the main world is stored in ScriptWrappable.  Wrapper
// objects for other worlds are stored in DOMDataStore.
```

`LocalDomWindow` defines a getter named `document()`:
```cpp
Document* LocalDOMWindow::document() const {
  return document_.Get();
}
```

It's defined as:
```cpp
Member<Document> document_;
```
** where is it initialized..?

## Layouting

** A layouting operation is triggered by ..?
```cpp
// In Blink, layouts always start from a relayout
// boundary (see ObjectIsRelayoutBoundary in layout_object.cc). As such, we
// need to mark the ancestors all the way to the enclosing relayout boundary in
// order to do a correct layout.
```

## Chromium source code

Blink is used mainly by the [content module](https://source.chromium.org/chromium/chromium/src/+/main:content/README.md).
** usages of blink ..?

> See [renderer/README.md](../README.md) for the relationship of `core/` to`modules/` and `platform/`.
> ...
> - [`renderer/`](renderer/README.md): code that runs in the renderer process

** Chromium source code is ..? https://source.chromium.org/chromium/chromium/src/ ..?

** `third_party/blink/` is ..? https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/ ..?
> .../blink/renderer: The web engine responsible for turning HTML, CSS and scripts into paint commands and other state changes.
 
See: https://docs.google.com/document/d/1aitSOucL0VHZa9Z2vbRJSyAIsAz24kX8LFByQ5xQnUg/edit

** `content/` is ..? https://source.chromium.org/chromium/chromium/src/+/main:content/ ..?
> content: The core code needed for a multi-process sandboxed browser (see below). More information about why we have separated out this code.

** `sandbox/` is ..? https://source.chromium.org/chromium/chromium/src/+/main:sandbox/
> sandbox: The sandbox project which tries to prevent a hacked renderer from modifying the system.

** `ui/views/` is ..? https://source.chromium.org/chromium/chromium/src/+/main:ui/views/
> ui/views: A simple framework for doing UI development, providing rendering, layout and event handling.
> Most of the browser UI is implemented in this system. This directory contains the base objects.
> Some more browser-specific objects are in chrome/browser/ui/views.

** `cc/` is ..? ..?
> cc: The Chromium compositor implementation.

** cc/raster , cc/paint, are ..?

** `third_party/blink/renderer/core/paint/` is ..?

