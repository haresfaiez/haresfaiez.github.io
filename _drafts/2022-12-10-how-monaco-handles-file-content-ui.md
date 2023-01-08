>> for 2* Feburary

The editor box is a div element called a widget.
`StandaloneEditor`, `EmbeddedCodeEditorWidget`, and other
subclasses of `CodeEditorWidget` create and manage it.
`CodeEditorWidget` is a huge absctract class.

A widget manages a text model (see previous post).
`CodeEditorWidget` defines a method `setModel` that accepts a `TextModel` instance.
It creates a view and renders it.
It initializes an editor, creates and keeps track of event handlers,
and holds references to services, models, and views.

The widget instance defines events for ui actions that other components
may to listen for them and execute some actions.
It fires events on keyUp, keyDown, mouseUp, and many others.
For example, the component, managing hover widgets that show
token definitions, listens for keyDown event to hide the description
widget.


# tokens -> HTML
A widget can be created to show and edit the code, to list search results,
or to show a diff.
The component creates a widget instance then sets a text model.
Widget constructor mainly initializes attributes and register basic event
handlers.

`_attachModel` called by `setModel` is the method respnosible for creating the box
we see on the screen.
It creates `ViewModel`, `View`, and `ModelData` instances.
ModelData holds reference to other classes to clean them when the model
changes.
The view holds a reference to the view model.
The view model holds a reference toward the text model.

`View` cosntructor creates the editor instance `div` element.
This contains two containers.
`_linesContent` manages the content.
It contains mainly the lines and the cursor.
`_overflowGuardContainer` contains components shown above the content.
We can find there the scroll bars, the minimap, and so on.

The constructor initilizes the box. It does not render the lines.
It sets the dimensions of the editor and creates empty containers and dom elements.
It creates elements for the ruler, lines, scrollbars, cursors and so on.
But, they are not added to the page.

Here's a part of `View` constructor:

```javascript
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

There are two kinds of elements. Elements that are part of the content,
added to `_linesContent`.
For example, inside this element, we find a div containning the code lines,
another div containing the vertical lisnes modeling the indentation levels
and red/green backgrounds describing deletions/insertinos in a diff.
And elements above the code, like scrollbars and line numbers.
These are added inside `_overflowGuardContainer`, a layer above the content.

`View` defines a method, `render`, to add insert the elements into the page.
Inisde `_attchModel`, the widget adds builds the dom element and inserts them into
the page.

The code is
```typescript
const [view, hasRealView] = this._createView(viewModel);
if (hasRealView) {
    this._domElement.appendChild(view.domNode.domNode);
    view.render(false, true);
}
```

`_domElement` here is the element injeced into the widget where to put the editor.
`hasRealView` is hard-coded to true inside `_createView`.

`View.render` is a short method.
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

`_viewLines`, same as other view parts, extends `ViewPart`, which itself
extends `ViewEventHandler`.
`forceShouldRender` is defined in `ViewEventHandler` as follows:
```typescript
public forceShouldRender(): void {
    this._shouldRender = true;
}
```

*** how `_shouldRender` is used

`_flushAccumulatedAndRenderNow()` will be invoked whether `now` is true or false.
If true, we invoke it directly.
If not, the invokation will be scheduled to the next animation frame.
[link to why we should schedule view updates to a new animation frame]
In the end, `_actualRender` is called.
This method essentially renders the lines in the current view port and all the view parts whose
`shouldRender` is true.

*** what else may cause inovkation of _flushAccumulatedAndRenderNow ?

# View parts

*** view.ts/View/viewParts : Added in view.ts/View/constructor
*** exemples of viewPart.render implementation

# Rendring a line
`ViewLines` creates the lines you see on the screen.
`View.render()` calls `ViewLines.renderText()`.

This is a simplified code of what happens:
```typescript
const partialViewportData = this._context.viewLayout.getLinesViewportData();
this._context.viewModel.setViewport(partialViewportData.startLineNumber, partialViewportData.endLineNumber, partialViewportData.centeredLineNumber);
const viewportData = new ViewportData(
    this._selections,
    partialViewportData,
    this._context.viewLayout.getWhitespaceViewportData(),
    this._context.viewModel
);
this._viewLines.renderText(viewportData);
```

The view finds the visible lines and displays just them.
As specified below, to find the visible lines. Monaco first finds the
top offset of the scroll. Then, uses it and the height of the code
box to determine which lines to render.

ViewLines keeps track of currently visible lines.
To render a range of lines,
In the first step, rendering the lines, there are two cases to handle.
If the new range of lines to show does not overlap with the currently visible
lines, we create the new lines.
If they overlap, we update untouched lines, then we remove/insert
new lines before or after the untoched ones.
To insert a line, it creates an instance of ViewLine.
To remove a line, it removes the DOM element from the page with `domNode.removeChild`.
To update an existing line, it updates its top offset and its height with set `_domNode.setTop` and `_domNode.setHeight`.
After having an object for each line we should render,
we render the line HTML.?

To render a range of lines, ViewLayer uses a string buffer.
It resets it, adds lines HTML to it one by one, then adds it to the page.

viewLine.ts/renderLine -> viewLineRenderer.ts/renderViewLine

A rendered line for
```javascript
    	private lineColor: string;
```
will look like this:
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

How line is rendered:
```javascript
const lineDomNode = line.getDomNode();
const renderResult = line.renderLine(i + rendLineNumberStart, deltaTop[i], this.viewportData, sb);
```

ViewLine colllects line data such content, tokens, before rendering.
Then, it adds line html code to the given string buffer.
Here's the main logic
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
It starts with creating a span to hold the line.
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
Here ViewLine makes the distinction between tokens that are white space
and other tokens.
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

*** line decorations?: actualInlineDecorations = LineDecoration.filter(lineData.inlineDecorations...
*** inline decorations??: // This line is empty, but it contains inline decorations
*** if (input.lineDecorations.length > 0) ??
*** RenderLineInput.startVisibleColumn ??
*** RenderLineInput.RenderLineInput ??
*** IViewLineTokens vs ModelTokens?
*** _renderLine/isOverflowing,fauxIndentLength,startVisibleColumn ??

# Rendring overlays
margins, the layer above the line, ....
*** ViewOverlays ??
*** ViewOverlays/createVisibleLine vs ViewLines/createVisibleLine
*** viewOverlays.ts/render ==> viewLayer.ts/ViewLayerRenderer/render --> /_finishRendering
  == > viewLine.ts/renderLine -> viewLineRenderer.ts/renderViewLine creates the HTML code for a given line
*** what are: ViewModel, ViewLayout, LinesLayout

*** view.ts/View/_selections?
*** coreCommands.ts/*
*** TextAreaHandler?

# View port
getLinesViewportData is defined as follows:

```javascript
public getLinesViewportData(): IPartialViewLinesViewportData {
    const visibleBox = this.getCurrentViewport();
    return this._linesLayout.getLinesViewportData(visibleBox.top, visibleBox.top + visibleBox.height);
}
```
ViewLayout keeps track of the scrolling state.
...? how scrolling state/events are managed

*** View/_actualRender: const viewportData = new ViewportData....

# Scroll
The steps inside ViewLines/renderText are the next
```javascript
// (1) render lines - ensures lines are in the DOM
// (2) compute horizontal scroll position
// (3) handle scrolling
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

# keyboard event listeners

# mouse event handlers (find usages for example)

# Reflections
- people often say that using strong tyes and type checking simplifies code.
Yes, it does. But, if you expect the input of the progarm to be fully typed,
then it's up to the user to fix type errors.
Most programming and ux done, is explaining how the given input does not fit,
or in limiting possible input.

# Next posts
- EditorTheme, ThemeSrevice, CodeEditorWidget._themeService