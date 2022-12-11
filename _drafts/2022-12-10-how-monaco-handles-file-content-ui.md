The box where we see and edit the code in Monaco is called a widget.
CodeEditorWidget creates and manages it.
It takes a dom element, options, and some services in the constructor.
It's a big class that's not instanciated directly, but extended by other classes
that can be instanciated.
StandaloneEditor, EmbeddedCodeEditorWidget, and many others can be instanciated.

This class is very big. It initializes the editor and keeps track of services,
event handlers, models, and views.
To have an editor, a widget should be instantiated and handed a text model.
We intorduced TextModel in a previous post and talked about how it handles
the code.

CodeEditorWidget defines a method setModel that accept the text model,
create a ViewModel, create a view, and then render it.
The widget instance defines events for ui actions that other components
may want to listen for them and execute some actions.
It fires events on keyUp, keyDown, mouseUp, and many others.
For example, the component, managing hover widgets that show
token definitions, listens for keyDown event to hide the description
widget.


# tokens -> HTML
View cosntructor creates a div to contain the editor instance.
This contains two containers. One, _linesContent,for the content. It contains mainly
the lines and the cursor.
The other, _overflowGuardContainer, contains components
dispaly above the content. It contains the scroll bars,
the minimap, and so on.

Here's the code from View constructor

```javascript
// The view context is passed on to most classes (basically to reduce param. counts in ctors)
this._context = new ViewContext(configuration, colorTheme, model);
this.domNode = createFastDomNode(document.createElement('div'));
this._linesContent = createFastDomNode(document.createElement('div'));
this._scrollbar = new EditorScrollbar(this._context, this._linesContent, this.domNode, this._overflowGuardContainer);
this._viewLines = new ViewLines(this._context, this._linesContent);
this._linesContent.appendChild(this._viewLines.getDomNode());
```

ViewLines is the class responsbile for creating the lines of code you
see on the screen.
View/render() indeed calls ViewLines/renderText().
This is a simplified code of what happens:
```javascript
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
The steps inside ViewLines/renderText are the next
```javascript
// (1) render lines - ensures lines are in the DOM
// (2) compute horizontal scroll position
// (3) handle scrolling
```

ViewLines keeps track of currently visible lines.
In the first step, rendering the lines, there are two cases to handle.
If the new range of lines to show does not overlap with the currently visible
lines, ...?
If they overlap, we update? untouched lines, then we remove and insert
new lines before or after.

To insert a line, it creates an instance of ViewLine.
To remove a line, it removes the DOM element from the page with `domNode.removeChild`.
To update an existing line, it updates its top offset and its height with set `_domNode.setTop` and `_domNode.setHeight`.





codeEditorWidget.ts/setModel -> _attachModel -> _createView ==>
view.ts/View constructor

view.ts/View render
viewOverlays.ts/render ==>
viewLayer.ts/ViewLayerRenderer/render --> /_finishRendering ==>
viewLine.ts/renderLine -> viewLineRenderer.ts/renderViewLine creates the HTML code for a given line

* view.ts/View: constructor vs render()
* view.ts/View/render: _flushAccumulatedAndRenderNow() vs _scheduleRender()
* Find out what flush* is called and what it does each time
* what are: ViewModel, ViewLayout, LinesLayout, EditorTheme
* view.ts/View/_selections?
* ViewOverlays/createVisibleLine vs ViewLines/createVisibleLine

# cursor
# keyboard event listeners
# mouse event handlers (find usages for example)
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
# view.ts/View/viewParts
# Reflections
- people often say that using strong tyes and type checking simplifies code.
Yes, it does. But, if you expect the input of the progarm to be fully typed,
then it's up to the user to fix type errors.
Most programming and ux done, is explaining how the given input does not fit,
or in limiting possible input.
