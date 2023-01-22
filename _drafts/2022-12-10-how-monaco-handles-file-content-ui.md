>> for 2* Feburary (Last post about Monace, review of last two books next)

`CodeEditorWidget` is a huge absctract class that connects
a `TextModel` explained in the previous post to HTML elements.
`StandaloneEditor` and `EmbeddedCodeEditorWidget` are examples of instantiable
subclasses that create editors.
They all implement a method `setModel` to create a div element, named a widget,
and to define its event handlers.

# From tokens to DOM elements
Editor `div` contains two sub containers.
A div for the text and the cursor, named `_linesContent`.
A div for the layer components above the content, `_overflowGuardContainer`.
We find in the first the lines of code,
the vertical lines respresenting indentation levels,
and the red/green backgrounds describing deletions/insertions in a diff.
The second contains scroll bars, minimaps, line numbers, and other layers
above the code.

Here's highlights from  `View` constructor:
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

The view here sets the dimensions of the editor and creates empty dom elements.
It creates elements for the ruler, lines container, scrollbars, cursors and so on.
But, they are not added to the page??.

We?? select a model to create an editor DOM element by calling `setModel`.
Technically, the widget instanciates a `ViewModel` and a `View`.
then adds it  calls `View.render()`.
`ViewModel` is a wrapper around the text model and a director for the view.
It keeps track of the edition state, cursors, selected sentences, scroll level,
and currently visible lines.
`View` is a dummy layer abover DOM.

Then, it renders the editor inside a `_domElement`,
an element that already exists in the page,
and that will contains the editor.

```typescript
const view = this._createView(viewModel);
this._domElement.appendChild(view.domNode.domNode);
view.render(false, true);
```

`View.render()` looks like this:
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

This is called either directly here, or during the next animation frame
when scheduled by `_scheduleRender`.
[link to why we should schedule view updates to a new animation frame]
This method essentially renders the lines
and all the view parts whose `shouldRender` is true.

All visible components extends `ViewPart`.
`forceShouldRender` above marks the view part as to-be-rendered.
The rendereng is triggered by `_flushAccumulatedAndRenderNow`.

Here's is a simplified code of rendering the lines:
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

And here's a simplified code of rendering the view parts, from the same method:
```typescript
viewport = .... // See previous snippet
let viewPartsToRender = this._viewParts.filter((viewPart) => viewPart.shouldRender());
for (const viewPart of viewPartsToRender) {
    viewPart.render(new RenderingContext(viewLayout, viewport, this._viewLines));
    viewPart.onDidRender();
}
```

`View` first renders a range of lines, by calling `ViewLines.renderText()`,
then renders other view parts, by calling `ViewPart.render()` for each.

Every rendering invocation gets a `ViewportData` instance from `ViewLayout`.
This structure contains description of the visible range and white space?? to render, and seletions??.

`getLinesViewportData` reads top and left scroll positions,
then uses the top offset together with the height of the editor
to get start and end lines numbers from the lines layout.

# View port and scrolling
Scrollbar is an example of how `View` and `ViewModel` collaborate.

A bird-view of the dependecy graph fro scrollbar-related classes might look like this:
```typescript
View -> EditorScrollbar -> AbstractScrollableElement -> HTMLElement
ViewModel -> ViewLayout -> EditorScrollable -> Scrollable
```

The names are quite confusing.
`ViewModel` creates a `ViewLayout`.
And, `ViewLayout` creates a scrolling model, `EditorScrollable`.
On the side, `View` creates a scrollbar element (`_scrollbar = new EditorScrollbar(...)`)
inside the overlay layer (`_overflowGuardContainer`) as in the first code snippet.

The scrollbar view model manages scrolling ??(or editor??) dimensions and scroll position.
It keeps trak of number attributes specfiying width, height, scroll width and height, top and left offsets, and so on.
It makes sure that updates to these values are valid.
A scroll left position for example should not go beyound the width.

It is called by??
It fires events after??
*** Events
  * EditorScrollable/onDidContentSizeChange
  * Scrollable/onScroll

`EditorScrollbar` creates and manages a div element which contains the lines container element,
the vertical scroll container element, and the horizontal scroll container element.
It accepts in its constructor the lines container, and creates the other two.
In `View` constructor above, in the first code snippet, the overflow layer is added
to the editor main div elmeent. But, the lines content element is not.

`AbstractScrollableElement` constructor contains:
```typescript
this._verticalScrollbar = this._register(new VerticalScrollbar(...));
this._horizontalScrollbar = this._register(new HorizontalScrollbar(...));

this._domNode = document.createElement('div');
this._domNode.className = 'monaco-scrollable-element ' + this._options.className;
this._domNode.setAttribute('role', 'presentation');
this._domNode.style.position = 'relative';
this._domNode.style.overflow = 'hidden';
this._domNode.appendChild(element); // `element` here is the DOM element containing the lines
this._domNode.appendChild(this._horizontalScrollbar.domNode.domNode);
this._domNode.appendChild(this._verticalScrollbar.domNode.domNode);
```

`VerticalScrollbar` and `HorizontalScrollbar` builds DOM elements for scroll bars.

It is called by??
It fires events after??
*** Events
  * AbstractScrollableElement/onWillScroll
  * AbstractScrollableElement/onScroll

*** propagation of scroll events??

`ViewLayout` manages two layouts. A scrollbar layout and a lines layout.
It creates a lines layout in the constructor.

The documentation of `LinesLayout` is as follows:
```typescript
/**
 * Layouting of objects that take vertical space (by having a height) and push down other objects.
 *
 * These objects are basically either text (lines) or spaces between those lines (whitespaces).
 * This provides commodity operations for working with lines that contain whitespace that pushes lines lower (vertically).
 */
export class LinesLayout {
```

`LinesLayout` creates `ViewPortData` inside `getLinesViewportData`.
`LinesLayout` keeps track of the number of lines and of a line height
and can tell which lines to render.
`ViewLayout` calls it with the offsets given by the scrollbar model as follows:
```typescript
const scrollDimensions = this._scrollable.getScrollDimensions();
const scrollPosition = this._scrollable.getCurrentScrollPosition();
return this._linesLayout.getLinesViewportData(
    scrollPosition.scrollTop,
    scrollPosition.scrollTop + scrollDimensions.height
);
```

The scrollbar height fits into the editor box. The lines meanwhile might not be fit inside the box.
The lines container contains only a range of lines at each time.
The scroll model supposes that the lines container is a div containing all the lines and that the scroll
is a pointer toward one line.
It keeps track of top offset of this line. 
`scrollPosition.scrollTop` received by `getLinesViewportData` is an top offset inside this imaginary long container.
`getLinesViewportData` here uses lines height to figure out which line the `scrollTop` points to,
and, which lines `scrollPosition.scrollTop + scrollDimensions.height` points to.

 Lines layout takes into account white spaces between lines in these computations.
 These are empty spaces reserved by `ViewZone`, and wich might contain components like
 [code lens descriptors](https://code.visualstudio.com/blogs/2017/02/12/code-lens-roundup).


# Rendring a line
Rendering this line of code:
```typescript
private lineColor: string;
```

looks like this:
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

`ViewLines` manages lines rendering.
As specified in the first code snippet, `View` creates `ViewLines`
and puts its DOM node inside the lines layer, `_linesContent`.

`ViewLines.renderText` takes a view port instance
and updates DOM elements then adapts the scroll??.

Rendering either resets the content of `ViewLines`
div by clearing it and putting elements for new lines ,
or changes its content by keeping and updating a range of lines, removing others,
and inserting new ones before or after.

To remove a range of lines, the renderer removes their DOM elements with `domNode.removeChild`.
To update an existing line, it updates its top offset and its height with set `_domNode.setTop` and `_domNode.setHeight`.
To insert a set of lines, it creates an instance of `ViewLine` for it.
At the end, after removing and updating other lines, the renderer adds the dom elements for these lines to the page.

As new lines belong to the same range.
Adding them at one time is optimal, and needs less DOM manipulations, than adding them together.
The renderer creates a string buffer and calls `ViewLine.renderLine`
with the line number, the top offset??, the view port data, and the string buffer, for each line.
The line view adds the string for the HTML element to this buffer.

Later, the string is added as:
```typescript
const lastChild = <HTMLElement>this.domNode.lastChild;
if (domNodeIsEmpty || !lastChild) {
    this.domNode.innerHTML = newLinesHTML as string; // explains the ugly casts -> https://github.com/microsoft/vscode/issues/106396#issuecomment-692625393;
} else {
    lastChild.insertAdjacentHTML('afterend', newLinesHTML as string);
}
```
`this.domNode` is the lines container div element.

ViewLine colllects line data such content tokens from `ViewModel`.
Then, it adds line html code to the given string buffer.

Here's the main logic:
```javascript
const renderLineInput = new RenderLineInput(
    //....
);

sb.appendASCIIString('<div style="top:');
sb.appendASCIIString(String(deltaTop));
sb.appendASCIIString('px;height:');
sb.appendASCIIString(String(this._options.lineHeight));
sb.appendASCIIString('px;" class="');
sb.appendASCIIString(ViewLine.CLASS_NAME);
sb.appendASCIIString('">');

const output = renderViewLine(renderLineInput, sb);

sb.appendASCIIString('</div>');
```

`renderViewLine`, indeed, builds the HTML code shown in the beginning of the section.

It starts with creating a span to hold the line:
```javascript
sb.appendASCIIString('<span ');
if (partContainsRTL) {
    sb.appendASCIIString('style="unicode-bidi:isolate" ');
}
sb.appendASCIIString('class="');
sb.appendASCIIString(partRendersWhitespaceWithWidth ? 'mtkz' : partType);
sb.appendASCII(CharCode.DoubleQuote);
```

Then, it iterates over tokens one by one.
Each inside a span with the type as the class name.
```javascript
sb.appendASCIIString('<span ');
if (partContainsRTL) {
    sb.appendASCIIString('style="unicode-bidi:isolate" ');
}
sb.appendASCIIString('class="');
sb.appendASCIIString(partRendersWhitespaceWithWidth ? 'mtkz' : partType);
sb.appendASCII(CharCode.DoubleQuote);
```

Here `ViewLine` makes the distinction between tokens that are white space and other types of tokens.
It converts the characters into ASCII codes and adds them.
For example, it converts a tab into `0x2192` and many `0xA0`, or into `0xFFEB` and many `0xA0`.
It converts a space into `` and `0x200C` if it's a whitespace token,
or into one or many `0xA0 // &nbsp` if it's just a space or a tab character into another token,
a less-than character into `&lt;`,
and so on.

And finally, it closes the span containing the line.
```javascript
// ...
sb.appendASCIIString('</span>');
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

# Rendring overlays & view parts
margins, the layer above the line, ....
*** ViewOverlays ??
*** ViewOverlays/createVisibleLine vs ViewLines/createVisibleLine
*** viewOverlays.ts/render ==> viewLayer.ts/ViewLayerRenderer/render --> /_finishRendering
  == > viewLine.ts/renderLine -> viewLineRenderer.ts/renderViewLine creates the HTML code for a given line

*** view.ts/View/_selections?
*** coreCommands.ts/*
*** TextAreaHandler?

*** view.ts/View/viewParts : Added in view.ts/View/constructor
**** ViewPart.: prepareRender vs. render vs. onDidRender
*** exemples of viewPart.render implementation
**** Steps to render/re-render these
```typescript
this._linesContent.appendChild(contentViewOverlays.getDomNode());
this._linesContent.appendChild(rulers.domNode);
this._linesContent.appendChild(blockOutline.domNode);
this._linesContent.appendChild(this._viewZones.domNode);
this._linesContent.appendChild(this._viewLines.getDomNode());
this._linesContent.appendChild(this._contentWidgets.domNode);
this._linesContent.appendChild(this._viewCursors.getDomNode());
this._overflowGuardContainer.appendChild(margin.getDomNode());
this._overflowGuardContainer.appendChild(this._scrollbar.getDomNode());
this._overflowGuardContainer.appendChild(scrollDecoration.getDomNode());
this._overflowGuardContainer.appendChild(this._textAreaHandler.textArea);
this._overflowGuardContainer.appendChild(this._textAreaHandler.textAreaCover);
this._overflowGuardContainer.appendChild(this._overlayWidgets.getDomNode());
this._overflowGuardContainer.appendChild(minimap.getDomNode());
```

# cursor
export class ViewCursors extends ViewPart

Cursors view is added in View.ts/View/constructor like this:
```javascript
this._viewCursors = new ViewCursors(this._context);
this._viewParts.push(this._viewCursors);
// ...
this._linesContent.appendChild(this._viewCursors.getDomNode());
```

*** Light blue background for token when hosvering on it?

# keyboard/mouse event listeners/handlers (find usages for example)




# Reflections
- people often say that using strong tyes and type checking simplifies code.
Yes, it does. But, if you expect the input of the progarm to be fully typed,
then it's up to the user to fix type errors.
Most programming and ux done, is explaining how the given input does not fit,
or in limiting possible input.

# Next posts
- EditorTheme, ThemeSrevice, CodeEditorWidget._themeService
- what about DiffEditorWidget?
- where to put these?
A widget defines ui events like `keyUp`, `keyDown`, `mouseUp`.
Other components wait for these triggers.
The component responsible for showing tokens definition as hover widgets,
for example, waits for keyDown event to hide the description widget.

In side a widget, we navigate and edit code, we search for occurences and
navigate the results, and we compute the differences between two versions of a file.


`CodeEditorWidget` constructor initializes services attributes and registers
event handlers.
The component?? creates a widget and sets a text model`.