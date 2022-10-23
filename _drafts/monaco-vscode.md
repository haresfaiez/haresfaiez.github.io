# How Monaco core handle file content
- // copy from below where _buffer is stored
- TextModel.buffer is an instance of ITextBuffer
export interface ITextBuffer extends IReadonlyTextBuffer {
	setEOL(newEOL: '\r\n' | '\n'): void;
	applyEdits(rawOperations: ValidAnnotatedEditOperation[], recordTrimAutoWhitespace: boolean, computeUndoEdits: boolean): ApplyEditsResult;
}
- _bufferDisposable has the type IDispose, which contain only one method, dispose
- _options contais source rules:
export class TextModelResolvedOptions {
	_textModelResolvedOptionsBrand: void = undefined;

	readonly tabSize: number;
	readonly indentSize: number;
	readonly insertSpaces: boolean;
	readonly defaultEOL: DefaultEndOfLine;
	readonly trimAutoWhitespace: boolean;
	readonly bracketPairColorizationOptions: BracketPairColorizationOptions;

- in the costructor also, we use the buffer to create helper objects

this._bracketPairs = this._register(new BracketPairsTextModelPart(this, this._languageConfigurationService));
this._guidesTextModelPart = this._register(new GuidesTextModelPart(this, this._languageConfigurationService));
this._tokenizationTextModelPart = new TokenizationTextModelPart(
			this._languageService,
			this._languageConfigurationService,
			this,
			this._bracketPairs,
			languageId
		);


which are defined as
	private readonly _tokenizationTextModelPart: TokenizationTextModelPart;
	private readonly _bracketPairs: BracketPairsTextModelPart;
	private readonly _guidesTextModelPart: GuidesTextModelPart;


- BracketPairTree creates an ast for brackets if possible (there's a limit for the number of lines)
						new BracketPairsTree(this.textModel, (languageId) => {
							return this.languageConfigurationService.getLanguageConfiguration(languageId);
						})
						
export class BracketPairsTree extends Disposable {
	/*
		There are two trees:
		* The initial tree that has no token information and is used for performant initial bracket colorization.
		* The tree that used token information to detect bracket pairs.

		To prevent flickering, we only switch from the initial tree to tree with token information
		when tokenization completes.
		Since the text can be edited while background tokenization is in progress, we need to update both trees.
	*/
		private initialAstWithoutTokens: AstNode | undefined;
	private astWithTokens: AstNode | undefined;

BracketPairsTree is a helper? class/object. It's instantiated when needed, each time the barckets are updated
	private updateBracketPairsTree() {
		if (this.bracketsRequested && this.canBuildAST) {
			if (!this.bracketPairsTree.value) {
				this.bracketPairsTree.value = createDisposableRef(
					store.add(
						new BracketPairsTree(this.textModel, (languageId) => {
							return this.languageConfigurationService.getLanguageConfiguration(languageId);
						})
					),
					store
				);
- updateBracketPairsTree is called from many locations
constructor/handleDidChangeOptions/handleDidChangeLanguage/
	/**
	 * Returns all bracket pairs that intersect the given range.
	 * The result is sorted by the start position.
	*/
	public getBracketPairsInRange(range: Range): BracketPairInfo[] {
/getBracketPairsInRangeWithMinIndentation/getBracketsInRange/findPrevBracket/findNextBracket

- TextModel.TokenizationTextModelPart contains a property backgroundTokenizationState that directs the ast
building? operation for a fast initial feedback and colorization, then a thougouht analysis
of the source.
defined as:
export const enum BackgroundTokenizationState {
	Uninitialized = 0,
	InProgress = 1,
	Completed = 2,
}
this state is declared and managed like this:
	private _backgroundTokenizationState = BackgroundTokenizationState.Uninitialized;
	public get backgroundTokenizationState(): BackgroundTokenizationState {
		return this._backgroundTokenizationState;
	}
	private handleTokenizationProgress(completed: boolean) {
		if (this._backgroundTokenizationState === BackgroundTokenizationState.Completed) {
			// We already did a full tokenization and don't go back to progressing.
			return;
		}
		const newState = completed ? BackgroundTokenizationState.Completed : BackgroundTokenizationState.InProgress;
		if (this._backgroundTokenizationState !== newState) {
			this._backgroundTokenizationState = newState;
			this.bracketPairsTextModelPart.handleDidChangeBackgroundTokenizationState();
			this._onBackgroundTokenizationStateChanged.fire();
		}
	}

- ?
ViewModelImpl: tokenizeViewPort(visiblerange)
-> TokenizationTextModelPart: tokenizeViewPort
	public tokenizeViewport(
		startLineNumber: number,
		endLineNumber: number
	): void {
		startLineNumber = Math.max(1, startLineNumber);
		endLineNumber = Math.min(this._textModel.getLineCount(), endLineNumber);
		this._tokenization.tokenizeViewport(startLineNumber, endLineNumber);
	}
-> TextModelTokens: tokenizeViewport (..., this._isTokenizationComplete())
 // _isTokenizationComplete here??
-> TokenizationTextModelPart: setTokens -> handleTokenizationProgress(completed?)

- ??			       difference between initialAstWithoutTokens and astWithTokens??
- usually used as
getDecorationsInRange
// ...
		const bracketsInRange = this.textModel.bracketPairs.getBracketsInRange(range);
		for (const bracket of bracketsInRange) {
			result.push({
				id: `bracket${bracket.range.toString()}-${bracket.nestingLevel}`,
				options: {
					description: 'BracketPairColorization',
					inlineClassName: this.colorProvider.getInlineClassName(
						bracket,
						this.colorizationOptions.independentColorPoolPerBracketType
					),
				},
--->
	public getBracketsInRange(range: Range): BracketInfo[] {
// ...
		const node = this.initialAstWithoutTokens || this.astWithTokens!;
		collectBrackets(node, lengthZero, node.length, startOffset, endOffset, result, 0, new Map());
--->
else if (node.kind === AstNodeKind.Bracket) {
		const range = lengthsToRange(nodeOffsetStart, nodeOffsetEnd);
		result.push(new BracketInfo(range, level - 1, 0, false));
	}

- tokenizationTextModelPart
- in the constructor we initialize
		this._tokens = new ContiguousTokensStore(
			this._languageService.languageIdCodec
		);
		this._semanticTokens = new SparseTokensStore(
			this._languageService.languageIdCodec
		);
		this._tokenization = new TextModelTokenization(
			_textModel,
			this,
			this._languageService.languageIdCodec
		);
- ContiguousTokensStore: Represents contiguous tokens in a text model?
- SparseTokensStore: Represents sparse tokens in a text model?
- TextModelTokenization:






- Tokenization?
- guidesTextModelPart?
- class CodeEditorWidget?
- 		this._decorationProvider = this._register(new ColorizedBracketPairsDecorationProvider(this));?




- Monaco uses a core and a set of plugins
- All code is in typescript.
- `monace-core` is defined in `vscode` repository, https://github.com/opensumi/monaco-editor-core
- the core is used by this editor, https://github.com/microsoft/monaco-editor
- which you can try here: https://microsoft.github.io/monaco-editor/index.htmlOB

# Model
- this model is to be passed later to a Monaco Editor instance that adds it to a webpage
```
monaco.editor.create(document.getElementById(containerId), { model: model });

```
- a model is usually managed by an Editor instance, for example an instance of StandaloneEditor
- When attaching a model to an editor, codeEditorWidget.ts/StandaloneEditor/_attachModel:
- an editor instance is an editor model: ITextModel
- createModel(language, url) -> ITextModel, which is ModelData.model == TextModel
- a model/instance has a unique id, usually the uri of the opened file
- tab? session? window? ...
- TextModel? has a mode?
- TextModelTokenization?
- Creating a new model is creating a new `ModelData`:
- `TextModel` has a buffer for the code string
- in the contstructuor it gets:
source: string | model.ITextBufferFactory
//...
const { textBuffer, disposable } = createTextBuffer(source, creationOptions.defaultEOL);
	this._buffer = textBuffer;
	this._bufferDisposable = disposable;
		this._options = TextModel.resolveOptions(this._buffer, creationOptions);


- ?? all the file content or just the visible part?
```
private _buffer: model.ITextBuffer;

```
-- checks whether first char is UTF8_BOM_CHARACTER
-- collect line starts (offsets of all CR, LF, CRLF)
-- normalize eol if needed
-- is
```
new PieceTreeTextBuffer(chunks, this._bom, eol, this._containsRTL, this._isBasicASCII, this._normalizeEOL)
```
-- begin tokenization (background tokenization?)

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
