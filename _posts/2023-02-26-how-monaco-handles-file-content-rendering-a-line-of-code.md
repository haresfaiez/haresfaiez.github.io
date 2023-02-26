---
layout:   post
comments: true
title:    "How Monaco handles file content: rendering a line of code"
date:     2023-02-26 12:02:00 +0100
tags:     featured
---

Rendering the editor as HTML requires the collaboration of
a widget, a model, a view, and a view model.
The widget acts as an orchestrator between the three other modules.
It arranges the rendering inside a `div` that exists already on the page.
You can open the inspector [here](https://microsoft.github.io/monaco-editor/playground.html)
and take a look at the HTML structure.
See how it changes when you edit the code.

To instantiate an editor,
we inject a [text model](/2022/10/16/how-monaco-handles-file-content-initialization.html) into a widget.
The widget creates `View` and `ViewModel` instances.
`View` creates UI components (lines, line numbers, ruler, ...) and puts them into the page.
Each component then asks `ViewModel` for the edition state and updates its DOM structure.
When scrolling, the scrollbar component detects the mouse wheel event and emits `ViewScrollChangedEvent` event.
The lines component handles this event and shows the new lines.


# The big picture
`ViewModel` is a thin layer around the text model.
It references currently visible lines, scroll level (first visible line), cursor location (line and column),
and selections.
These are windows into the model.
`View` uses them as a model for the editing state.

`View` is a dumb layer above the DOM API.
It instantiates components
(source code lines, ruler, scrollbars, cursors, ...).
It creates empty containers for them.
And, inside `View#render`, it finds which components need rendering
and triggers rendering for each one of them.

This rendering method is called during initialization and after a component handles an event
(for example, after the lines component handle scrolling event,
or after the cursor component handles the click event).

Components extend `ViewPart`.
Each of them creates an HTML element in the constructor.
Then, it updates the element structure and style inside a `render` method.
`ViewPart` itself extends `ViewEventHandler`.
That way, a component handles events by overriding handlers.
The lines component, for example, handles the scrolling event by overriding `onScrollChanged`
and changing the visible range of lines.

Rendering operations, for all components, get a `viewport` instance.
This instance acts as a rendering context.
It contains a visible range of lines, white spaces between lines, and selections.
`ViewModel` creates it by reading top and left scroll offsets,
then using the top offset and the height of the editor
to find the first and the last line numbers.


# Rendering lines
The `ViewLines` component manages DOM elements for source code lines.

Rendering this line of code:
```typescript
private lineColor: string;
```

gives this HTML output:
```HTML
<div style="top: 396px; height: 18px;" class="view-line">
    <span>
        <span class="mtk1">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span class="mtk6">private</span>
        <span class="mtk1">&nbsp;lineColor:&nbsp;</span>
        <span class="mtk6">string</span>
        <span class="mtk1">;</span>
    </span>
</div>
```

`ViewLines` manages a `div` to contain elements similar to the one in the previous snippet.
Rendering a range of lines usually resets the content of this
container and puts elements for new lines in place.

If the container already contains a range of lines,
and if some of these lines should stay after we call `ViewLines#render`,
the renderer first updates these lines' top positions.
Then, it removes `div`s of no-longer-needed lines.
Finally, it inserts new lines at the beginning and the end.

Inserting a range of lines is an optimized process.
New lines are added either at the beginning or at the end of the container.
The renderer optimizes DOM manipulations by adding a range of lines at once to the page.
First thing during rendering, it creates an instance of `ViewLine` for each line.
Then, after removals and updates, it collects DOM elements for these instances
into a string and inserts it into the page:

```typescript
this.domNode.lastChild.insertAdjacentHTML('afterend', newLinesHTML as string);
```
`this.domNode` is the container element.
`this.domNode.lastChild` is the last line in the container before rendering.
`newLinesHTML` is the new lines HTML string.

`ViewLine` collects line tokens from `ViewModel`,
build the line `div` element,
and adds it to the given string buffer, `newLinesHTML`:

```typescript
const renderLineInput = new RenderLineInput(/* ... */);

stringBuffer.appendASCIIString('<div style="top:');
stringBuffer.appendASCIIString(String(deltaTop));
stringBuffer.appendASCIIString('px;height:');
stringBuffer.appendASCIIString(String(this._options.lineHeight));
stringBuffer.appendASCIIString('px;" class="');
stringBuffer.appendASCIIString(ViewLine.CLASS_NAME);
stringBuffer.appendASCIIString('">');

const output = renderViewLine(renderLineInput, stringBuffer);

stringBuffer.appendASCIIString('</div>');
```

`renderViewLine` builds the HTML code shown at the beginning of the section.
Each token is represented by a `span` whose class name is the token type.

```typescript
stringBuffer.appendASCIIString('<span ');
if (partContainsRTL) {
    stringBuffer.appendASCIIString('style="unicode-bidi:isolate" ');
}
stringBuffer.appendASCIIString('class="');
stringBuffer.appendASCIIString(partRendersWhitespaceWithWidth ? 'mtkz' : partType);
stringBuffer.appendASCII(CharCode.DoubleQuote);
```

`ViewLine` makes the distinction between white space tokens and other types of tokens.
It converts the characters into ASCII codes and adds them.
For example, it converts a tab into `0x2192` and many `0xA0`, or into `0xFFEB` and many `0xA0`.
It converts into one or many `0xA0 // &nbsp`.

To remove a range of lines, the renderer removes each one of their DOM elements
with [`Node.removeChild`](https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild).
 
To update the position of a line, it changes its top offset and height
by setting [`style.top`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style)
and [`style.height`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style).


# Creating the viewport
There is one global `View` and one global `ViewModel`.
Then, there are component-specific `View` and `ViewModel` classes.
The creation of `viewport` is a sample of how `View` and `ViewModel` collaborate.
We talked about `viewport` in the first section.
It's created by the view model
and injected into all rendering operations.

A bird-view of the dependency graph for scrollbar-related classes looks like this:
```typescript
View -> EditorScrollbar -> AbstractScrollableElement -> HTMLElement
ViewModel -> ViewLayout -> EditorScrollable -> Scrollable
```

`View` creates a scrollbar component (`_scrollbar = new EditorScrollbar(...)`).
`EditorScrollbar` manages a container `div`. It contains the lines,
the vertical scroll, and the horizontal scroll.
We can think of the lines component as a child of the scrollbar component.

`AbstractScrollableElement`, a helper of `EditorScrollbar` creates this container:
```typescript
this._verticalScrollbar = this._register(new VerticalScrollbar(...));
this._horizontalScrollbar = this._register(new HorizontalScrollbar(...));

this._domNode = document.createElement('div');
this._domNode.appendChild(element); // `element` here is the DOM element containing the lines
this._domNode.appendChild(this._horizontalScrollbar.domNode.domNode);
this._domNode.appendChild(this._verticalScrollbar.domNode.domNode);
```

`Scrollable` detects scrolling on the div by handling mouse wheel events.
It communicates the movement to `EditorScrollable`, the scrollbar view model,
which emits `ViewScrollChangedEvent` if scrolling is permitted.
That is if the scroll is not yet at its limit.

The editor box might not contain all the lines of a given file.
`EditorScrollable`, decides which range of lines to show.
It keeps track of the editor width and height, the scroll width and height,
and of the scroll top and left offsets.
It validates any update to these values.
It makes sure, for example, that the left scroll position does not go beyond the scrollbar width.

The scrollbar layout imagines the lines container to be a container `div`
with a child `div` for each line.
And, it needs to point toward the top offset of the first line.
This is just imagination because, on the page, there are elements only
for the visible lines.

`viewLayout#getLinesViewportData` creates the `viewport`:
```typescript
const scrollDimensions = this._scrollable.getScrollDimensions();
const scrollPosition = this._scrollable.getCurrentScrollPosition();
return this._linesLayout.getLinesViewportData(
    scrollPosition.scrollTop,
    scrollPosition.scrollTop + scrollDimensions.height
);
```
This is a collaboration between the scrollbar view model and the lines view model.
`this._scrollable` is the scrollbar view model, an instance of `EditorScrollable`.
`this._linesLayout` is part of the lines view model, an instance of `LinesLayout`.
`getLinesViewportData` uses line height to figure out to which line the `scrollTop` points,
and to which line `scrollPosition.scrollTop + scrollDimensions.height` points.

`LinesLayout` keeps track of the number of lines and of line height.
The documentation of `LinesLayout` says:
```typescript
/**
 * Layouting of objects that take vertical space (by having a height) and push down other objects.
 *
 * These objects are basically either text (lines) or spaces between those lines (whitespaces).
 * This provides commodity operations for working with lines that contain whitespace that pushes lines lower (vertically).
 */
export class LinesLayout {
```

Whitespace regions are empty spaces reserved by `ViewZone`.
They might contain components like
[code lens descriptors](https://code.visualstudio.com/blogs/2017/02/12/code-lens-roundup).


# Code for writing code
When we click and start typing,
many components contribute to the movement of the cursor
and to the creation of HTML elements for the tokens we write.

`ViewOverlays` manages line decoration.
When we focus on a line, the background might change
or a `2px` light-grey border might appear.
The overlay container element contains a `div` for each visible line.
This `div` is positioned behind the lines.
Styles, such as border and background, are added there for highlight.

A focused line can be:
```HTML
<div style="position: absolute; top: 18px; width: 100%; height: 18px; ">
    <div style="
        position: absolute;
        background-color: #add6ff;
        top: 0px;
        left: 108px;
        width: 80px;
        height: 18px;
        ">
    </div>
    <div style="
        position: absolute;
        box-sizing: border-box;
        box-shadow: 21px 0 0 0 #c7ff00 inset;
        left: 0px;
        height: 18px;
        width: 7.21484375px;
        ">
    </div>
</div>
```
The parent `div` models a line.
The first child models a selected section.
The second child models the indentation level vertical bar.
A non-focused line `div` is usually empty.

`ViewCursors` manages cursor position.
Its HTML element looks like this:
```HTML
<div
    style="position: absolute;"
    >
    <div style="
        position: absolute;
        overflow:hidden;
        background-color: #f00;
        border-color: #000000;
        color: #ffffff;
        height: 18px;
        top: 180px;
        left: 165px;
        display: block;
        visibility: hidden;
        width: 2px;
        ">
    </div>
</div>
```
`visibility` in the style of the child `div` bounces between `inherit` and `hidden` as the cursor blinks.

`TextAreaHandler` manages a `textarea` to receive what we type.
This element changes position as the cursor moves.
When we click at the beginning of the second line, the element will look like this:
```HTML
<textarea
    data-mprt="6"
    autocorrect="off"
    autocapitalize="none"
    autocomplete="off"
    spellcheck="false"
    style="
        position: absolute;
        overflow: hidden;
        color: transparent;
        background-color: transparent;
        letter-spacing: 0px;
        top: 18px;
        left: 62px;
        width: 0px;
        height: 18px;
    "
    wrap="off"
    >
</textarea>
```

`View` attaches a `MouseDown` listener to the editor DOM node.
It executes a `MoveToCommand` in the handler.
When `ViewModel` gets this command, it emits `ViewCursorStateChangedEvent`.
`View` uses commands to communicate with `ViewModel`.

Many components handle `ViewCursorStateChangedEvent`.
`ViewCursors` override `onCursorStateChanged` from `ViewEventHandler` and triggers blinking.
Cursor visibility changes every 500 milliseconds.
`TextAreaHandler` overrides `onCursorStateChanged` and updates the edition state.
`ViewOverlays` overrides `onCursorStateChanged` and highlights the target line.

When a component handles an event and the handler returns a truthy value,
the component is marked for re-rendering.
The check for which components to render is frequent.
So, the renderings of all components ready for rendering
are executed during the same animation frame.
It's more optimal to change all DOM elements at once
than to do it separately for each component.
`scrollTop` and `scrollLeft` for DOM elements are changed
inside rendering methods.

As we type a character,
`TextAreaHandler` `textarea` element is reset and moved one step to the right
to receive the next character.
The `TextAreaHandler` component listens to the `textarea` `input` event.
When triggered, the handler notifies the widget,
which in turn notifies `ViewModel` of the entered text.
`ViewModel` then creates and executes commands
to reset the `textarea`, update the text model,
and emit `CursorStateChangedEvent` event.
This pushes the cursor to the right.
