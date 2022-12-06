---
layout:   post
comments: true
title:    "How Monaco handles file content: Models updates"
date:     2022-10-22 12:02:00 +0100
tags:     featured
---

Here's what the documentation says:

```
// We do a first pass to update tokens and decorations
// because we want to read decorations in the second pass
// where we will emit content change events
// and we want to read the final decorations
```

Editor workers and plugin components detect buffer updates by
listening to IModelContentChangedEvent event.
Component that manage tokens colorization, editor workers, and code diff calculators,
wait for this event to update their models.


# Tokens model update
- _tokenizationTextModelPart.acceptEdit
- TokenizationTextModelPart.handleDidChangeContent

- 
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
- difference between initialAstWithoutTokens and astWithTokens ?


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

# Brackets model update
- BracketPairsImpl.handleDidChangeContent
- BracketPairsTree is a helper? class/object. It's instantiated when needed, each time the barckets are updated
private updateBracketPairsTree() {
this.bracketPairsTree.value = createDisposableRef(
	store.add(
		new BracketPairsTree(this.textModel, (languageId) => this.languageConfigurationService.getLanguageConfiguration(languageId))),
	store
);
- updateBracketPairsTree is called from many locations
constructor/handleDidChangeOptions/handleDidChangeLanguage/

# Next post subjects
- Decoration model: why ignoring TextModel._decorationstree?

