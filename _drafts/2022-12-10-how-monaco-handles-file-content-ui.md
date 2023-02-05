>> for 2* Feburary (Last post about Monaco, review of last two books next)
---
layout:   post
comments: true
title:    "How Monaco handles file content: rendering a line of code"
date:     2023-02-26 12:02:00 +0100
tags:     featured
---

`CodeEditorWidget` is a huge absctract class that links
a [`TextModel`](explained in the previous post) to HTML elements.
Subsclasses, such as `StandaloneEditor` and `EmbeddedCodeEditorWidget`,
create and manage the editors we interact with on the screen.
They render the editor inside a `_domElement`,
an element that already exists in the page.

TLDR;
The ?? gives a text model to a widget.
The widget creates `View` and `ViewModel`.
`View` creates empty DOM elements for editor UI components,
asks `ViewModel` for the range of lines to render,
and creates DOM elements for these lines.
?? cursor

?? when scrolling, `View` tells `ViewModel` about the scroll event,
?? `ViewModel` tells `View` which lines to render. `View` udpates DOM lines elements.
?? curor update

# What do we get
You might want to open the inspector [here](https://microsoft.github.io/monaco-editor/index.html)
and see how HTML is structured and what changes when you edit the code.

Editor is a `div` composed from many containers.
One `div` for lines, named `_linesContent`,
and another `div` for above-the-content??? layer, `_overflowGuardContainer`.
The first contains the lines of code,
the red/green backgrounds describing deletions/insertions in a diff,
and the vertical lines respresenting indentation levels.
The second contains scroll bars, minimaps, line numbers.
*** Describe the end structure ?
*** `_linesContent` div children vs. adjacent elements


# Rendring a line
Rendering this line of code:
```typescript
private lineColor: string;
```

gives this HTML output:
```html
<div style="top:396px;height:18px;" class="view-line">
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
It creates `div` element to contain source lines `div` elements.

Rendering a range of lines either resets the content of this
`div` to put elements for new lines inplace, or it updates its content.
It keeps a range of lines,
updates and removes other ranges,
and inserts anew ranges at the beginning and at the end.

To remove a range of lines, the renderer removes their DOM elements
with [`Node.removeChild`(]https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild).
 
To update an existing line, it updates its top offset and its height
with set [`style.top`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style)
and `[style.height`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/style).

New lines belong to the same range.
to insert a set of lines, the renderer creates an instance of `ViewLine`
for each line.
At the end, after removing and updating other ranges, the renderer
adds the dom elements for these `ViewLine` instances to the page at one time.
Adding all of them at together is optimal.
This needs less DOM manipulations than adding them one by one.

HTML for these lines are collected inside one string that is added as:
```typescript
const lastChild = this.domNode.lastChild;
if (domNodeIsEmpty || !lastChild) {
    this.domNode.innerHTML = newLinesHTML as string;
} else {
    lastChild.insertAdjacentHTML('afterend', newLinesHTML as string);
}
```
`this.domNode` is the lines container `div` element
and `newLinesHTML` is the string containing HTML for the new lines.

The renderer creates a string buffer and builds the string by passing the
buffer to `ViewLine.renderLine`.
For line here `ViewLine` collects line data such line text and tokens from `ViewModel`
and adds line html code to the given string buffer.

Here's the main logic:
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

`renderViewLine`, indeed, builds the HTML code shown in the beginning of the section.

It starts with creating a span to hold the line:
```javascript
stringBuffer.appendASCIIString('<span ');
if (partContainsRTL) {
    stringBuffer.appendASCIIString('style="unicode-bidi:isolate" ');
}
stringBuffer.appendASCIIString('class="');
stringBuffer.appendASCIIString(partRendersWhitespaceWithWidth ? 'mtkz' : partType);
stringBuffer.appendASCII(CharCode.DoubleQuote);
```

Then, it puts tokens in one by one, each inside a `span` with the type as the class name:
```javascript
stringBuffer.appendASCIIString('<span ');
if (partContainsRTL) {
    stringBuffer.appendASCIIString('style="unicode-bidi:isolate" ');
}
stringBuffer.appendASCIIString('class="');
stringBuffer.appendASCIIString(partRendersWhitespaceWithWidth ? 'mtkz' : partType);
stringBuffer.appendASCII(CharCode.DoubleQuote);
```

Here `ViewLine` makes the distinction between white space tokens and other types of tokens.
It converts the characters into ASCII codes and adds them.
For example, it converts a tab into `0x2192` and many `0xA0`, or into `0xFFEB` and many `0xA0`.
It converts a space into `` and `0x200C` if it's a whitespace token,
or into one or many `0xA0 // &nbsp` if it's just a space or a tab character into another token,
a less-than character into `&lt;`,
and so on.

And finally, it closes the span containing the line.
```javascript
// ...
stringBuffer.appendASCIIString('</span>');
```

*** ViewModelLines?
*** line decorations?: actualInlineDecorations = LineDecoration.filter(lineData.inlineDecorations...
*** inline decorations??: // This line is empty, but it contains inline decorations
*** if (input.lineDecorations.length > 0) ??
*** RenderLineInput.startVisibleColumn ??
*** RenderLineInput.RenderLineInput ??
*** IViewLineTokens vs ModelTokens?
*** _renderLine/isOverflowing,fauxIndentLength,startVisibleColumn ??
*** ViewLines/renderText/(2) and (3)
The steps inside ViewLines/renderText are the next
```javascript
// (1) render lines - ensures lines are in the DOM
// (2) compute horizontal scroll position
// (3) handle scrolling
```

# How it all began
Widget classes define editor DOM elements inside `setModel` method.
Technically, this method takes a text model and instanciates a `ViewModel` and a `View`.

`ViewModel` is a wrapper for the text model and a director for the view.
It keeps track of edition states, cursors, selected sentences, scroll level,
and currently visible lines.

`View` is a dumb layer above DOM Api.
It creates empty elements for containers for each of the ruler,
the lines, the scrollbars, the cursors and so on.
It's called to put source code and decorations into the page.

Here's highlights from DOM elements creation inside `View` constructor:
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

`View.render()`, which puts the code inside the empty container, looks like this:
```typescript
public render(now: boolean, everything: boolean): void {
    if (everything) {
        // Force everything to render...
        this._viewLines.forceShouldRender();
        for (const viewPart of this._viewParts) {
            viewPart.forceShouldRender();
        }
    }
    if (now) {
        this._flushAccumulatedAndRenderNow();
    } else {
        this._scheduleRender();
    }
}
```

Visible components extends `ViewPart`.
`forceShouldRender` here marks the view-part as to-be-rendered.
The rendereng is triggered by `_flushAccumulatedAndRenderNow`,
which is called either directly, or during the next animation frame
when scheduled by `_scheduleRender`.
[link to why we should schedule view updates to a new animation frame]

*** when to we need it `everything === false`?

Here's is some code from `_flushAccumulatedAndRenderNow`.
It renders the lines of code:
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
this._viewLines.renderText(viewport);
```

And here's a simplified code that renders other view parts from the same method.
```typescript
let viewPartsToRender = this._viewParts.filter((viewPart) => viewPart.shouldRender());
for (const viewPart of viewPartsToRender) {
    viewPart.render(new RenderingContext(viewLayout, viewport, this._viewLines));
    viewPart.onDidRender();
}
```

`View` first renders a range of lines by calling `ViewLines.renderText()`,
then renders other view parts by calling `ViewPart.render()`.
`viewport` and `viewLayout` are defined here, then used during both rendrings.
Renderings get a `ViewportData` instance.
This structure groups visible range, white space?? to render, and seletions??.
The visible range, `partialViewport`, is calculated by `ViewLayout.getLinesViewportData`.
`getLinesViewportData` reads top and left scroll positions,
then uses the top offset together with the height of the editor
to find out the first and last line numbers.


# View port and scrolling
Scrollbar is an example of how `View` and `ViewModel` collaborate.

A bird-view of the dependecy graph for scrollbar-related classes looks like this:
```typescript
View -> EditorScrollbar -> AbstractScrollableElement -> HTMLElement
ViewModel -> ViewLayout -> EditorScrollable -> Scrollable
```

Let's check `View`-related classes first.
`View` creates a scrollbar element (`_scrollbar = new EditorScrollbar(...)`)
inside the overflow layer (`_overflowGuardContainer`).
See the first code snippet for context.

`EditorScrollbar` creates and manages a `div` element containing the lines,
the vertical scroll, and the horizontal scroll.
It takes the lines container from the `View`, and creates the other two.
`VerticalScrollbar` and `HorizontalScrollbar` builds DOM elements for scroll bars.

`AbstractScrollableElement` constructor contains:
```typescript
this._verticalScrollbar = this._register(new VerticalScrollbar(...));
this._horizontalScrollbar = this._register(new HorizontalScrollbar(...));

this._domNode = document.createElement('div');
this._domNode.appendChild(element); // `element` here is the DOM element containing the lines
this._domNode.appendChild(this._horizontalScrollbar.domNode.domNode);
this._domNode.appendChild(this._verticalScrollbar.domNode.domNode);
```

It is called by??
It fires events after??
*** Events
  * AbstractScrollableElement/onWillScroll
  * AbstractScrollableElement/onScroll

*** propagation of scroll events??

On to view model classes now.
`ViewModel` creates a `ViewLayout`.
`ViewLayout` manages two layouts.
A scrollbar layout and a lines layout.

The editor box might not fit all the lines.
`EditorScrollable`, the scrollbar view model, decides which range of lines to show.
It manages scrolling ??(or editor??) dimensions and scroll position.
It keeps trak of width, height, scroll width and height, top and left offsets, and so on.
It validates updates to these values.
It makes sure, for example, that left scroll position does not go beyound the width.

It is called by??
It fires events after??
*** Events
  * EditorScrollable/onDidContentSizeChange
  * Scrollable/onScroll

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

`LinesLayout` keeps track of the number of lines and of line height.
It takes into account white spaces between lines during view port calculation.
These are empty spaces reserved by `ViewZone`, and wich might contain components like
[code lens descriptors](https://code.visualstudio.com/blogs/2017/02/12/code-lens-roundup).

Here's some code from `viewLayout.getLinesViewportData()` called above:
```typescript
const scrollDimensions = this._scrollable.getScrollDimensions();
const scrollPosition = this._scrollable.getCurrentScrollPosition();
return this._linesLayout.getLinesViewportData(
    scrollPosition.scrollTop,
    scrollPosition.scrollTop + scrollDimensions.height
);
```

`this._scrollable` is the scrollbar model, an instance of `EditorScrollable`.

The scrollbar view model imagines that the lines container is a long `div` containing all the lines
and it points toward the top offset of the first line.
`getLinesViewportData` uses lines height to figure out which line the `scrollTop` points to,
and which line `scrollPosition.scrollTop + scrollDimensions.height` points to.


# Code for writing code
The editor is composed from view components.
Each implements `ViewPart` and defines a `render` method.
Each also creates a new HTML element in the constructor
and updates its DOM structure and style inside `render`.
We'll focus on `ViewOverlays`, `ViewCursor`, and `TextAreaHandler` as samples.

`ViewOverlays` creates and manages a `div` and manage line docoration and selection.

`ViewOverlays` is added in `View` constructor as:
```typescript
const contentViewOverlays = new ContentViewOverlays(/*...*/);
this._viewParts.push(contentViewOverlays);
contentViewOverlays.addDynamicOverlay(new SelectionsOverlay(/*...*/));
contentViewOverlays.addDynamicOverlay(new IndentGuidesOverlay(/*...*/));
//...
this._linesContent.appendChild(contentViewOverlays.getDomNode());
```

When you focus on a line, you notice that it's highlighted in some way.
The background might change or a 2px light-grey border might appear.
Also, when you select a part, the selection might be highlighted
with a light blue background.
The view overlay element contains a `div` for each visible line.
This `div` contains the decoration.

The main `div` is rendered behind the lines div as:
```HTML
<div class="view-overlays" style="position: absolute; top: 0px; height: 0px; width: 605px;" role="presentation" aria-hidden="true">
```

An example of a focused line can be:
```HTML
<div style="position:absolute;top:18px;width:100%;height:18px;">
    <div style="position:absolute;background-color:#add6ff;top:0px;left:108px;width:80px;height:18px;"></div>
    <div style="position:absolute;box-sizing:border-box; box-shadow:21px 0 0 0 #c7ff00 inset;left:0px;height:18px;width:7.21484375px"></div>
</div>
```
The parent `div` models a line.
The first child models a selected portion.
The second child models an indentation level vertical bar.
A non-focused lines `div` is either empty,
or it contains only the indentation indicator.

`ViewCursor` is added in `View` constructor like this:
```typescript
this._viewCursors = new ViewCursors(/*...*/);
this._viewParts.push(this._viewCursors);
// ...
this._linesContent.appendChild(this._viewCursors.getDomNode());
```

Its HTML element looks like this:
```HTML
<div role="presentation" aria-hidden="true" style="position: absolute;">
    <div style="position: absolute;overflow:hidden;background-color: #f00;border-color: #000000;color: #ffffff;height: 18px; top: 180px; left: 165px; font-family: Menlo, Monaco, &quot;Courier New&quot;, monospace; font-weight: normal; font-size: 12px; font-feature-settings: &quot;liga&quot; 0, &quot;calt&quot; 0; line-height: 18px; letter-spacing: 0px; display: block; visibility: hidden; width: 2px;">
    </div>
</div>
```
`visiblity` in the style of the child `div` bounces between `inherit` and `hidden`.

`TextAreaHandler` is the textarea that will receive the code we write.
It's added in `View` constructor like this:
```typescript
this._textAreaHandler = new TextAreaHandler(/*...*/);
this._viewParts.push(this._textAreaHandler);
// ...
this._overflowGuardContainer.appendChild(this._textAreaHandler.textArea);
```

It creates and manages a `textarea` element.
This element follows the cursor. It changes position after a click
and after moving the cursor with the keyboard.

When we click in the beginning of the second line, the element will look as:
```HTML
cursor: text;
.monaco-editor .inputarea {
	min-width: 0;
	min-height: 0;
	margin: 0;
	padding: 0;
	position: absolute;
	outline: none !important;
	resize: none;
	border: none;
	overflow: hidden;
	color: transparent;
	background-color: transparent;
}
<textarea data-mprt="6" class="inputarea monaco-mouse-cursor-text" autocorrect="off" autocapitalize="none" autocomplete="off" spellcheck="false" aria-label="Editor content;Press Alt+F1 for Accessibility Options." tabindex="0" role="textbox" aria-roledescription="editor" aria-multiline="true" aria-haspopup="false" aria-autocomplete="both" style="font-family: Menlo, Monaco, &quot;Courier New&quot;, monospace; font-weight: normal; font-size: 12px; font-feature-settings: &quot;liga&quot; 0, &quot;calt&quot; 0; line-height: 18px; letter-spacing: 0px; top: 18px; left: 62px; width: 0px; height: 18px;" wrap="off">
</textarea>
```

When you click on a token in a line and type, ...?
*** How `ViewOverlays`, `ViewCursor`, `TextAreaHandler` DOM are updated? Steps to render/re-render these

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
