- `monace-core` is defined in `vscode` repository, https://github.com/opensumi/monaco-editor-core
- the core is used by this editor, https://github.com/microsoft/monaco-editor



- class CodeEditorWidget?
  		this._decorationProvider = this._register(new ColorizedBracketPairsDecorationProvider(this));?


- a model is usually managed by an Editor instance, for example an instance of StandaloneEditor
- When attaching a model to an editor, codeEditorWidget.ts/StandaloneEditor/_attachModel:
- an editor instance is an editor model: ITextModel
- createModel(language, url) -> ITextModel, which is ModelData.model == TextModel
- a model/instance has a unique id, usually the uri of the opened file
- tab? session? window? ...
- TextModel? has a mode?
- TextModelTokenization?
- Creating a new model is creating a new `ModelData`:
- ?? all the file content or just the visible part?

## Mode
- language?
- `ModeService`, `common/modes` `common/modes/*ProviderRegistery`

## Editor instance
// ...
const cursor = new Cursor(this._configuration, model, viewModel);
// ...
const view = new View(
			commandDelegate,
			this._configuration,
			this._themeService,
			viewModel,
			cursor,
			viewOutgoingEvents
		);
// ...
this._modelData = new ModelData(model, viewModel, cursor, view, hasRealView, listenersToRemove);

```

## Resource
- has uri (model.uri === "inmemory://model/1")

## Editor action

## Threads
- Main
- EditorWorkerService

## Case study: auto-suggestion

## Case study: bracket matching
- a div code contains a list of `div>span`
- an other div contains line highlights and parentheses/brackets hover style.
Parallel to the other list, each line has a div
```
.monaco-editor .bracket-match { background-color: rgba(0, 100, 0, 0.1); }
.monaco-editor .bracket-match { border: 1px solid #b9b9b9; }
```
and
```
<div style="position:absolute;top:1235px;width:100%;height:19px;">
<div class="current-line" style="width:1062px; height:19px;">
</div>
<div class="cigr" style="left:0px;height:19px;width:33.71875px">
</div>
<div class="cigra" style="left:33.71875px;height:19px;width:33.71875px">
</div>
<div class="cdr bracket-match" style="left:556px;width:9px;height:19px;">
</div>
</div>
```
- how such `div` are added:
 -- you hover next to a bracket: onMouseDown listener > find click position > execute mouse command (moveTo)
    ... > cursor change fire
    `this._onDidChange.fire(new CursorStateChangedEvent(selections, newState.modelVersionId, oldSelections, oldModelVersionId, source || 'keyboard', reason));`
    because of previous `editor.onDidChangeCursorPosition` `_updateBracketsSoon.schedule()` is called > `_recomputeBrackets()`
 -- checks the current selection and looks for the closing bracket of each opening one
    For that, it uses a configuration (the set of brackets, open/close, and a regex to find one) associated to the current model language.
    Visit the following lines one by one.
    Init a `count` to 1, increment it on an opening and decrement it on a closing until it reaches 0.
    Then stop and return the closing bracket.
 -- maps each bracket open/close to a decoration


## View
- vscode create a `textarea` element which moves to the current curson position.
  It has width/height=1 and it changes only its left/top attributes


# `monace-core`
- `StaticService` singleton for services
`StaticServices.modelService.get()`
- to change the selected language
```javascript
if (typeof value !== 'undefined') {
var oldModel = model;
model = monaco.editor.createModel(value, mode);
editor.setModel(model);
if (oldModel) {
oldModel.dispose();
}
} else {
monaco.editor.setModelLanguage(model, mode);
}
```
## Editor contribution
- Contributions are added as extensions
```
registerEditorContribution(BracketMatchingController.ID, BracketMatchingController);
registerEditorAction(SelectToBracketAction);
registerEditorAction(JumpToBracketAction);
registerThemingParticipant((theme, collector) => {
	const bracketMatchBackground = theme.getColor(editorBracketMatchBackground);
	if (bracketMatchBackground) {
		collector.addRule(`.monaco-editor .bracket-match { background-color: ${bracketMatchBackground}; }`);
	}
	const bracketMatchBorder = theme.getColor(editorBracketMatchBorder);
	if (bracketMatchBorder) {
		collector.addRule(`.monaco-editor .bracket-match { border: 1px solid ${bracketMatchBorder}; }`);
	}
});

// Go to menu
MenuRegistry.appendMenuItem(MenuId.MenubarGoMenu, {
	group: '5_infile_nav',
	command: {
		id: 'editor.action.jumpToBracket',
		title: nls.localize({ key: 'miGoToBracket', comment: ['&& denotes a mnemonic'] }, "Go to &&Bracket")
	},
	order: 2
});
```
- `CodeEditorWidget` creates contributions
```
let contributions: IEditorContributionDescription[];
	contributions = EditorExtensionsRegistry.getEditorContributions();
for (const desc of contributions) {
	try {
const contribution = this._instantiationService.createInstance(desc.ctor, this);
this._contributions[desc.id] = contribution;
	} catch (err) {
onUnexpectedError(err);
	}
}
```
## Events
- `Disposable` is an abstract class. Implements `dispose` (calls dispose recursively
on children) and `_register` (attaches a child).
- `Emitter`/`Event` to listen/fire events.
```
class LanguageSelection extends Disposable implements ILanguageSelection {
// ...
private readonly _onDidChange: Emitter<LanguageIdentifier> = this._register(new Emitter<LanguageIdentifier>());
public readonly onDidChange: Event<LanguageIdentifier> = this._onDidChange.event;
```
Then, to dispose of that
```
                if (this._languageSelection) {
                        this._languageSelection.dispose();
                        this._languageSelection = null;
                }
```
- Events leads to dependency inversion. For example, in bracket matching contribution
```
export class BracketMatchingController extends Disposable implements IEditorContribution {
//...
		this._register(editor.onDidChangeCursorPosition((e) => {

			if (this._matchBrackets === 'never') {
				// Early exit if nothing needs to be done!
				// Leave some form of early exit check here if you wish to continue being a cursor position change listener ;)
				return;
			}

			this._updateBracketsSoon.schedule();
		}));
		this._register(editor.onDidChangeModel((e) => {
			this._lastBracketsData = [];
			this._decorations = [];
			this._updateBracketsSoon.schedule();
		}));
```

