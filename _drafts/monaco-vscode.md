- Monaco uses a core and a set of plugins
- All code is in typescript.
- `monace-core` is defined in `vscode` repository
- `var model = monaco.editor.createModel('', 'plaintext') `
creates an editor model.

# Editor instance

## Mode
- language?
- `ModeService`, `common/modes` `common/modes/*ProviderRegistery`

## Model
- tab? session? window? ...
- TextModel? has a mode?
- TextModelTokenization?
- To attach a created model to an editor instance
```
		model = monaco.editor.createModel(value, mode);
		editor.setModel(model);
```

- Creation
```
/**
 * Create a new editor model.
 * You can specify the language that should be set for this model or let the language be inferred from the `uri`.
 */
export function createModel(value: string, language?: string, uri?: URI): ITextModel {
```

This usually returns
```
return StaticServices.modelService.get().createModel(value, StaticServices.modeService.get().create(language), uri)
```
- Creating a new model is creating a new `ModelData`:
```
createModel() {
//...
const model: TextModel = new TextModel(value, options, languageIdentifier, resource);
const modelId = MODEL_ID(model.uri);
const modelData = new ModelData(
	model,
	(model) => this._onWillDispose(model),
	(model, e) => this._onDidChangeLanguage(model, e)
);
//...
modelData.setLanguage(languageSelection); // languageSelection = StaticServices.modeService.get().create(language)
```
- `TextModel` has a buffer for the code string
```
this._buffer
```
-- checks whether first char is UTF8_BOM_CHARACTER
-- collect line starts (offsets of all CR, LF, CRLF)
-- normalize eol if needed
-- is
```
new PieceTreeTextBuffer(chunks, this._bom, eol, this._containsRTL, this._isBasicASCII, this._normalizeEOL)
```
-- begin tokenization (background tokenization?)


## Editor instance
- `StandaloneEditor` vs. `StandaloneCodeEditor`?
- model is used to create editor instance
- standalone
- In `StandaloneCodeEditor`, we update the editor model
```
let _model: ITextModel | null | undefined = options.model;
// ...
let model: ITextModel | null;
if (typeof _model === 'undefined') {
	model = (<any>self).monaco.editor.createModel(options.value || '', options.language || 'text/plain');
	this._ownsModel = true;
} else {
	model = _model;
	this._ownsModel = false;
}

this._attachModel(model);
if (model) {
	let e: IModelChangedEvent = {
		oldModelUrl: null,
		newModelUrl: model.uri
	};
	this._onDidChangeModel.fire(e);
}
```


- `this._onDidChangeModel.fire(e)` fires model update listeners
-- modes.CompletionProviderRegistry.has(model


-  `StandaloneCodeEditor` > `CodeEditorWidget`
-> attachModel
```
const viewModel = new ViewModel(
	this._id,
	this._configuration,
	model,
	DOMLineBreaksComputerFactory.create(),
	MonospaceLineBreaksComputerFactory.create(this._configuration.options),
	(callback) => dom.scheduleAtNextAnimationFrame(callback)
);
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
