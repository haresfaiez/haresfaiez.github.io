---
layout:   post
comments: true
title:    "How Monaco handles file content: rendering a line of code"
date:     2023-02-26 12:02:00 +0100
tags:     featured
---

Rendering the editor as HTML elements requires a collaboration between
a model, a view model, and a widget.
Widget classes such as `StandaloneEditor` and `EmbeddedCodeEditorWidget`
directs the rendering inside an element that already exists on the page.

You might want to open the inspector [here](https://microsoft.github.io/monaco-editor/)
and see how initial HTML structure and how it changes when you edit the code.

TLDR;
The ?? gives a text model to a widget.
The widget creates `View` and `ViewModel`.
`View` creates empty DOM elements for editor UI components.
It asks `ViewModel` for the range of lines to render.
Then, it creates DOM elements for these lines.

*** check these
?? When scrolling, `View` tells `ViewModel` about the scroll event,
?? `ViewModel` tells `View` which lines to render. `View` udpates DOM lines elements.


# How it starts
We crate an editor by calling `setModel` and passing in a text model.
This method instanciates a `ViewModel` and a `View`, and triggers rendering.

`ViewModel` is a wrapper around the text model.
It keeps track of the model informations that matter to the view.
It references currently visible lines, scroll level, cursor reference,
and selected sentences.
And, a director for the view.

`View` is a dumb layer above the DOM Api.
In its contstructor, it creates container elements for each of the ruler,
the lines, the scrollbars, the cursors and so on.
Later, it's called to render source code and decorations.

Here's highlights from `View` constructor:
```typescript
this._overflowGuardContainer = createFastDomNode(document.createElement('div'));
this.domNode = createFastDomNode(document.createElement('div'));
this._linesContent = createFastDomNode(document.createElement('div'));
this._scrollbar = new EditorScrollbar(this._context, this._linesContent, this.domNode, this._overflowGuardContainer);
this._viewParts.push(this._scrollbar);
this._viewLines = new ViewLines(this._context, this._linesContent);
this._linesContent.appendChild(this._viewLines.getDomNode());
this._overflowGuardContainer.appendChild(this._scrollbar.getDomNode());
this.domNode.appendChild(this._overflowGuardContainer);
```

*** Usage of View constructor and of View.render ?

`View.render()` puts the code inside the empty container.
Here's its main logic:
```typescript
public render(): void {
    // Force everything to render...
    this._viewLines.forceShouldRender();
    for (const viewPart of this._viewParts) {
        viewPart.forceShouldRender();
    }

    this._flushAccumulatedAndRenderNow();
}
```

View components extends `ViewPart`.
`forceShouldRender` marks a view-part as to-be-rendered.
`_flushAccumulatedAndRenderNow` triggers rendering.
First, it renders a range of lines by calling `ViewLines.renderText()`.
Then, it renders other view parts by calling `ViewPart.render()` for each part.

Here's how it rendrers the lines:
```typescript
this._viewLines.renderText(viewport);
```

And here's how it renders other view parts:
```typescript
let viewPartsToRender = this._viewParts.filter((viewPart) => viewPart.shouldRender());
for (const viewPart of viewPartsToRender) {
    viewPart.render(new RenderingContext(viewLayout, viewport, this._viewLines));
    viewPart.onDidRender();
}
```

`viewport` and `viewLayout` are used for both rendrings.

They're defined in the same method:
```typescript
const partialViewport = viewLayout.getLinesViewportData();
viewModel.setViewport(
    partialViewport.startLineNumber,
    partialViewport.endLineNumber,
    partialViewport.centeredLineNumber
);
const viewport = new ViewportData(
    this._selections,
    partialViewport,
    viewLayout.getWhitespaceViewportData(),
    viewModel
);
```

`viewport` is a `ViewportData` instance.
This structure groups visible range, white spaces between lines, and seletions.
`partialViewport` specifies the visible range.
`getLinesViewportData` reads top and left scroll positions.
It uses the top offset and the height of the editor
to find out the first and last line numbers.


# What ViewModel is about
The scrollbar is an example of how `View` and `ViewModel` collaborate.

A bird-view of the dependecy graph for scrollbar-related classes looks like this:
```typescript
View -> EditorScrollbar -> AbstractScrollableElement -> HTMLElement
ViewModel -> ViewLayout -> EditorScrollable -> Scrollable
```

`View` creates a scrollbar element (`_scrollbar = new EditorScrollbar(...)`).
See the first code snippet for context.

`EditorScrollbar` creates and manages a container `div` for the lines,
the vertical scroll, and the horizontal scroll.
It takes the lines container from the `View`, and creates containers for the scrollbars.

`AbstractScrollableElement` constructor contains:
```typescript
this._verticalScrollbar = this._register(new VerticalScrollbar(...));
this._horizontalScrollbar = this._register(new HorizontalScrollbar(...));

this._domNode = document.createElement('div');
this._domNode.appendChild(element); // `element` here is the DOM element containing the lines
this._domNode.appendChild(this._horizontalScrollbar.domNode.domNode);
this._domNode.appendChild(this._verticalScrollbar.domNode.domNode);
```
`VerticalScrollbar` and `HorizontalScrollbar` build DOM elements for scroll bars.


View classes are direcetd by view model classes.
`ViewModel` creates a `ViewLayout`.
`ViewLayout` manages two layouts. A scrollbar layout and a lines layout.
Layout is name used for components view models.

The editor box might not contain all the lines of a given file.
`EditorScrollable`, the scrollbar view model, decides which range of lines to show.
It keeps track of editor width and height, scroll width and height,
top and left offsets, and so on.
It validates any update to these values.
It makes sure, for example, that left scroll position does not go beyound the width.

The scrollbar layout imagines the lines container to be a very long `div`
that contains a `div` for each line.
And, it needs to point toward the top offset of the first line.

*** Events
  * it fires/it listens to
  * AbstractScrollableElement/onWillScroll
  * AbstractScrollableElement/onScroll
*** propagation of scroll events

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

*** Events
  * it fires/it listens to
  * EditorScrollable/onDidContentSizeChange
  * Scrollable/onScroll

`LinesLayout` keeps track of the number of lines and of line height.
It uses these values, together with the whitespace references, to find out visible range of lines.
`viewLayout.getLinesViewportData()`, called above, is collaboration between the scrollbar layout
and the lines layout.:
```typescript
const scrollDimensions = this._scrollable.getScrollDimensions();
const scrollPosition = this._scrollable.getCurrentScrollPosition();
return this._linesLayout.getLinesViewportData(
    scrollPosition.scrollTop,
    scrollPosition.scrollTop + scrollDimensions.height
);
```
`this._scrollable` is the scrollbar view model, an instance of `EditorScrollable`.
`this._linesLayout` is the lines view model, an instance of `LinesLayout`.
`getLinesViewportData` uses lines height to figure out which line the `scrollTop` points to,
and which line `scrollPosition.scrollTop + scrollDimensions.height` points to.


# Rendering a line
Rendering this line of code:
```typescript
private lineColor: string;
```

gives this HTML output:
```html
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

`ViewLines` manages line rendering.
As part of the view, it manages DOM elements.

It creates a container `div` and fills it with lines `div` elements.
The process is the same for rendering the first lines initially
and for changing the visible lines after scrolling.
The container `div` is always there.

Rendering a range of lines resets the content of the
container and puts elements for new lines inplace if
all the lines needs to change.
If some lines should stay, the renderer keeps a range of lines
and updates their top position,
removes other ranges,
and inserts new ranges at the beginning and at the end.

To remove a range of lines, the renderer removes their DOM elements
with [`Node.removeChild`(]https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild).
 
To update a ranges of lines, it udpates them one by one.
For each line, it updates its top offset and its height
with set [`style.top`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style)
and `[style.height`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style).

To insert a range of lines, the renderer optimizes DOM manipulations by
adding a range of lines at once to the page.
New lines belong to one or two ranges.
They are added either to the beginning or to the end of the container.
The renderer creates an instance of `ViewLine` for each line.
Later, after removals and updates, it collects DOM elements for these `ViewLine` instances
into a string and inserts it to the page.

```typescript
this.domNode.lastChild.insertAdjacentHTML('afterend', newLinesHTML as string);
```
`this.domNode` is the line container `div` element.
`this.domNode.lastChild` is last line initially in the container.
`newLinesHTML` is the string containing HTML for the new lines.

`ViewLine` too is a view classes.
It collects line data such line text and tokens from `ViewModel`
and adds line html code to the given string buffer.

Here's the main logic.
It starts with creating a `div` to hold the line:
```javascript
const renderLineInput = new RenderLineInput(
    //....
);

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
`renderViewLine` builds the HTML code shown in the beginning of the section.

Then, it inserts the tokens in one by one
Here's how the renderer creates a token.
Each token is represented by `span` element whose class name is the type.
```javascript
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
It converts a space into `` and `0x200C` if it's a whitespace token,
or into one or many `0xA0 // &nbsp` if it's just a space or a tab character into another token,
a less-than character into `&lt;`,

Finally, it closes the span containing the line.
```javascript
// ...
stringBuffer.appendASCIIString('</span>');
```

*** ViewModelLines?
*** IViewLineTokens vs ModelTokens?
*** line decorations?: actualInlineDecorations = LineDecoration.filter(lineData.inlineDecorations...
    "if (input.lineDecorations.length > 0)": inline decorations??: // This line is empty, but it contains inline decorations
*** RenderLineInput.startVisibleColumn ??
*** RenderLineInput.RenderLineInput ??
*** _renderLine/isOverflowing,fauxIndentLength,startVisibleColumn ??
*** ViewLines/renderText/(2) and (3)
The steps inside ViewLines/renderText are the next
```javascript
// (1) render lines - ensures lines are in the DOM
// (2) compute horizontal scroll position
// (3) handle scrolling
```

# Code for writing code
The editor is made from multiple view components.
Each one of them implements `ViewPart` interface,
creates a new HTML element in the constructor,
updates its DOM structure and style inside `render` method.

`ViewOverlays` is a component that creates and manage line docoration
and code selection.The view overlay element is a container `div`
that contains a `div` for each visible line.
This `div` contains the decoration. It can be a border, a background, or an
indentation vertical line.

When we focus on a line, we notice that it's highlighted in some way.
The background might change or a `2px` light-grey border might appear around it.
In the same way, when we you select a part, the selection might be highlighted
with a light blue background.

The main `div` is rendered behind the lines `div` as:
```HTML
<div
    class="view-overlays"
    style="position: absolute; top: 0px; height: 0px; width: 605px;"
    role="presentation"
    aria-hidden="true"
    >
```

An example of a focused line can be:
```HTML
<div style="position: absolute; top: 18px; width: 100%; height: 18px; ">
    <div style="position: absolute; background-color: #add6ff; top: 0px; left: 108px; width: 80px; height: 18px;">
    </div>
    <div style="position: absolute; box-sizing: border-box;  box-shadow: 21px 0 0 0 #c7ff00 inset; left: 0px; height: 18px; width: 7.21484375px;">
    </div>
</div>
```
The parent `div` here models a line.
The first child models the selected portion.
The second child models the indentation level vertical bar.
A non-focused lines `div` is either empty,
or it contains only the indentation indicator.

`View` adds the component inside its constructor:
```typescript
const contentViewOverlays = new ContentViewOverlays(/*...*/);
this._viewParts.push(contentViewOverlays);
contentViewOverlays.addDynamicOverlay(new SelectionsOverlay(/*...*/));
contentViewOverlays.addDynamicOverlay(new IndentGuidesOverlay(/*...*/));
//...
this._linesContent.appendChild(contentViewOverlays.getDomNode());
```

`ViewCursors` is a component that manages the cursors, mainly the indicator
of the insertion position.

Its HTML element looks like this:
```HTML
<div
    role="presentation"
    aria-hidden="true"
    style="position: absolute;"
    >
    <div
        style="
            position: absolute;
            overflow:hidden;
            background-color: #f00;
            border-color: #000000;
            color: #ffffff;
            height: 18px;
            top: 180px;
            left: 165px;
            font-family: monospace;
            font-weight: normal;
            font-size: 12px;
            font-feature-settings: &quot;liga&quot; 0, &quot;calt&quot; 0;
            line-height: 18px;
            letter-spacing: 0px;
            display: block;
            visibility: hidden;
            width: 2px;
        ">
    </div>
</div>
```
`visiblity` in the style of the child `div` bounces between `inherit` and `hidden`
when the cursor is blinking.

`ViewCursors` is added inside `View` constructor like this:
```typescript
this._viewCursors = new ViewCursors(/*...*/);
this._viewParts.push(this._viewCursors);
// ...
this._linesContent.appendChild(this._viewCursors.getDomNode());
```

`TextAreaHandler` manages the `textarea` that receives the code we write.
This element follows the cursor. It changes position after moving the cursor,
either on click or after typing arrows from the keyboard.

When we click in the beginning of the second line, the element will look as:
```HTML
<textarea
    data-mprt="6"
    autocorrect="off"
    autocapitalize="none"
    autocomplete="off"
    spellcheck="false"
    aria-label="Editor content;Press Alt+F1 for Accessibility Options."
    tabindex="0"
    role="textbox"
    aria-roledescription="editor"
    aria-multiline="true"
    aria-haspopup="false"
    aria-autocomplete="both"
    style="
        position: absolute;
        outline: none !important;
        resize: none;
        border: none;
        overflow: hidden;
        color: transparent;
        background-color: transparent;

        font-family: monospace;
        font-weight: normal;
        font-size: 12px;
        font-feature-settings: &quot;liga&quot; 0, &quot;calt&quot; 0;
        line-height: 18px;
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

It's added in `View` constructor like this:
```typescript
this._textAreaHandler = new TextAreaHandler(/*...*/);
this._viewParts.push(this._textAreaHandler);
// ...
this._overflowGuardContainer.appendChild(this._textAreaHandler.textArea);
```

When you click on a token in a line and type, ...?
*** How `ViewOverlays`, `ViewCursor`, `TextAreaHandler` DOM are updated? Steps to render/re-render these

We have `ViewPart extends ViewEventHandler`.


click
....
-> CursorController/eventsCollector.emitViewEvent(new ViewCursorStateChangedEvent(viewSelections, selections));
....
-> ViewModelEventDispatcher/public endEmitViewEvents(): void {
-> ViewModelEventDispatcher/private _doConsumeQueue(): void {
-> ViewEventHandler/public handleEvents(events: viewEvents.ViewEvent[]): void {
-> ViewEventHandler/case viewEvents.ViewEventType.ViewCursorStateChanged: if (this.onCursorStateChanged(e)) {shouldRender = true;}
-> ViewCursors/public override onCursorStateChanged(e: viewEvents.ViewCursorStateChangedEvent): boolean


ViewModelEventDispatcher/public endEmitViewEvents(): void {
-> ViewModelEventDispatcher/private _doConsumeQueue(): void {
-> ViewEventHandler/public handleEvents(events: viewEvents.ViewEvent[]): void {
-> case viewEvents.ViewEventType.ViewConfigurationChanged:if (this.onConfigurationChanged(e)) {shouldRender = true;
-> ViewCursors/public override onConfigurationChanged(e: viewEvents.ViewConfigurationChangedEvent): boolean {


Starttyping: (moves only after starting typing?)
TextAreaWrapper/this._register(new DomEmitter(this._actual, 'compositionstart')).event
-> TextAreaInput/this._register(this._textArea.onCompositionUpdate((e) => {
-> TextAreaHandler/this._register(this._textAreaInput.onCompositionStart
-> TextAreaHandler/render




`TextAreaHandler` constructor defines event handlers for focus and input.

ViewAreaHandler/constructor (		
    this._register(this._textAreaInput.onFocus(() => {
			this._context.viewModel.setHasFocus(true);
		}));
)
ViewModelImpl/setHasFocus (this._eventDispatcher.emitOutgoingEvent(new FocusChangedEvent(!hasFocus, hasFocus));)
ViewModelEventDispatcher/_doConsumeQueue
View/handleEvents (callse this._scheduleRender)??

 -> ViewEventHandler/handleEvents(event[i].type === viewEvents.ViewEventType.ViewFocusChanged)
 -> this.onFocusChanged(e) -> this._updateBlinking()
