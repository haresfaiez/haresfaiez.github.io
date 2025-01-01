---
layout: post
comments: true
title:  "How chromium reacts to a surprise style element"
date:   2024-12-09 10:00:00 +0100
tags: featured
---

** The browser is ..?
** Chromium is ..?
** You can read more about browser internals at...?

```markdown
Core rendering encompasses four key stages:

* [DOM](dom/README.md)
* [Style](css/README.md)
* [Layout](layout/README.md)
* [Paint](paint/README.md)

Other aspects of rendering are implemented outside of `core/`, such as
[compositing](../platform/graphics/compositing/README.md) and
[accessibility](../modules/accessibility/).
```
** explain each stage..?


Chromium is designed as a "a multi-process sandboxed browser".
** exlpain more..?

## What's a document

```markdown
+------------------+
|   Frame (Local)  | <-- Represents browsing context
+------------------+
          |
          v
+------------------+
|     Document     | <-- Represents the DOM of the page
+------------------+
          |
          v
+------------------+
|   LayoutView     | <-- Root of the layout tree
+------------------+
          ^
          |
+------------------+
|   FrameView      | <-- Manages viewport, scrolling, and lifecycle
+------------------+
```
** explain these and their relationships..?

** `FrameView` vs `LayoutView` is ..?
** ChatGPT says:
```markdown
| **Aspect**         | **Frame**                          | **LayoutView**                     |
|---------------------|-------------------------------------|-------------------------------------|
| **Purpose**         | Manages browsing context, document | Manages layout tree for rendering  |
| **Scope**           | Document-level                    | Layout tree root                   |
| **Hierarchy**       | Supports parent-child frames       | Independent of frame hierarchy     |
| **Relationships**   | Coupled with `Document` and `FrameTree` | Coupled with layout objects         |
| **Responsibilities**| Navigation, scripting, lifecycle   | Geometry, visual organization      |
| **Shared State**    | Frame-wide resources (security, etc.) | Layout-wide state                  |
```

`LayoutView` documentation says:
```cpp
// LayoutView is the root of the layout tree and the Document's LayoutObject.
//
// It corresponds to the CSS concept of 'initial containing block' (or ICB).
// http://www.w3.org/TR/CSS2/visudet.html#containing-block-details
//
// Its dimensions match that of the layout viewport. This viewport is used to
// size elements, in particular fixed positioned elements.
// LayoutView is always at position (0,0) relative to the document (and so isn't
// necessarily in view).
// See
// https://www.chromium.org/developers/design-documents/blink-coordinate-spaces
// about the different viewports.
//
// Because there is one LayoutView per rooted layout tree (or Frame), this class
// is used to add members shared by this tree (e.g. m_layoutState or
// m_layoutQuoteHead).
```

`LayoutObject` is explained in the next section:
```cpp
// LayoutObject is the base class for all layout tree objects.
//
// LayoutObjects form a tree structure that is a close mapping of the DOM tree.
// The root of the LayoutObject tree is the LayoutView, which is the
// LayoutObject associated with the Document.
// ...
// The purpose of the layout tree is to do layout (aka reflow) and store its
// results for painting and hit-testing. Layout is the process of sizing and
// positioning Nodes on the page.
```

# Layouting

** Layouting is ..?
```cpp
// Layout is the process of sizing and positioning Nodes on the page.
```
** Layouting is implemented by Blink?? (`renderer/core/layout`)
** `Blink's new layout engine “LayoutNG”.` ..?
** `The original design document can be seen here.` ..? (https://docs.google.com/document/d/1uxbDh4uONFQOiGuiumlJBLGgO4KDWB8ZEkp7Rd47fw4/edit)
** -- (https://chromium.googlesource.com/chromium/src/+/main/third_party/blink/renderer/core/layout/layout_ng.md)
Layout is based on [the box model](https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/The_box_model).
> Everything in CSS has a box around it, and understanding these boxes is key to being able to create more complex layouts with CSS, or to align items with other items.

** The result of layouting is ..?
```cpp
// The purpose of the layout tree is to do layout (aka reflow) and store its
// results for painting and hit-testing.
```
** Technically, this is ..?

Among the vocabulary needed for understading layouting are "constraint space", "fragments", and "logical / physical units".

** Constraint space is ..?
> A NGConstraintSpace represents the available space to perform the current layout in.

** A fragment is ..?
> The NGFragment contains two rects. One is it’s “border-box” rect (inlineSize, blockSize),
> the other is it’s overflow rect (inlineOverflowSize, blockOverflowSize).
>
> An NGFragment’s rect should not be larger than the NGConstraintSpace allows,
> but the overflow rect may be any size.
>
> Some layout algorithms take the overflow rect into account when positioning (block-flow), while others do not (flex).
> If the current layout will produce a NGFragment which will produce an overflow rect which will be larger than the scroll line,
> it can finish its current layout early with a “Trigger Scroll” flag.
> If a parent layout receives a NGFragment with this flag, it must perform layout on the child again with a new
> constraint space which allows space for the scroll bar. This new constraint space will not have the “scroll trigger offset” on it.
> (It must perform layout again as the child may have run an incomplete layout).

** physical vs logical offsets/coordinates..?
> To aid in readability and to ensure proper conversion between coordinate systems
> a set of dedicated units will be used to represent offsets, locations, sizes,
> and rects for each coordinate system where they are applicable. Conversion between
> coordinate systems must be done explicitly and no implicit conversion will be allowed.
> -- https://docs.google.com/document/d/1uxbDh4uONFQOiGuiumlJBLGgO4KDWB8ZEkp7Rd47fw4/edit

Difference:
> These are all in a logical coordinate space in the sense that they do not take
> writing mode or directionality into account.
...
> These are all in a physical coordinate space in the sense that they represent
> coordinates in a top-to-bottom, left-to-right coordinate system.
> Converting from a logical unit to a physical one thus requires the coordinates to be resolved.
> The Writing Modes and Coordinate Systems section goes into more details.


> During paint or when querying the layout tree (for clientRects, etc) a set of convenience methods
> are provided that gives the physical location or size of a NGFragment relative to its parent.
```cpp
NGPhysicalLocation NGFragment::getPhysicalLocation(const NGFragment* parent) const;
NGPhysicalSize NGFragment::getPhysicalSize(const NGFragment* parent) const;
```

** Implementation of physical and logical units..?

> CSS has many different types of layout modes, controlled by the display property.
> (In addition to this specific HTML elements have custom layout modes as well).
> For each different type of layout, we have a LayoutAlgorithm.
> The input to an LayoutAlgorithm is the same tuple for every kind of layout:
>
> * The BlockNode which we are currently performing layout for. The following information is accessed:
>   ** The ComputedStyle for the node which we are currently performing laying for.
>   **  The list of children BlockNodees to perform layout upon, and their respective style objects.
> * The ConstraintSpace which represents the “space” in which the current layout should produce a PhysicalFragment.

A `BlockNode` represents a DOM node.
** Such `BlockNode` instance is ..? It defines methods to ..., such as ..?

`BlockNode` constructor takes a `LayoutBox` instance:

```cpp
// LayoutBox implements the full CSS box model.
```

** It defines methods for ..., such as ..? `LogicalLeft/LogicalWidth/PhysicalSize Size ...`..?

** We have `LayoutBox < LayoutBoxModelObject < LayoutObject` ..?
** `LayoutObject` is ..?
```cpp
// LayoutObject is the base class for all layout tree objects.
//
// LayoutObjects form a tree structure that is a close mapping of the DOM tree.
// The root of the LayoutObject tree is the LayoutView, which is the
// LayoutObject associated with the Document.
```

Each layouting algorithm is represented by a distinc class that extends a parent
class named `LayoutAlgorithm`:

```cpp
// Base class template for all layout algorithms.
//
// Subclassed template specializations (actual layout algorithms) are required
// to define the following two functions:
//
//   MinMaxSizesResult ComputeMinMaxSizes(const MinMaxSizesFloatInput&);
//   const LayoutResult* Layout();
//
// ComputeMinMaxSizes() should compute the min-content and max-content intrinsic
// sizes for the given box. The result should not take any min-width, max-width
// or width properties into account.
//
// Layout() is the actual layout function. Lays out the children and descendants
// within the constraints given by the ConstraintSpace. Returns a layout result
// with the resulting layout information.
```

For `display: 'block';` layout, we have `BlockLayoutAlgorithm`.
For `diplay: 'flex'`, we have `FlexLayoutAlgorithm`.

** Who and where is the layout algorithm selected..?

Let's start by understanding a simple block-flow with one `DIV` element,
let's take this test from `BlockLayoutAlgorithmTest`:

```cpp
// Preparing a Document
// document = dummy_page_holder_->frame_->DomWindow()->document()

// Both sets the inner html and runs the document lifecycle.
document.body()->setInnerHTML(R"HTML(<div id="box" style="width:30px; height:40px"></div>)HTML", ASSERT_NO_EXCEPTION);
document.View()->UpdateAllLifecyclePhasesForTest();

// Building a ConstraintSpace instance
LayoutUnit fragmentainer_space_available;
WritingDirectionMode writing_direction = {WritingMode::kHorizontalTb, TextDirection::kLtr};
LogicalSize size = LogicalSize(LayoutUnit(100), kIndefiniteSize);
ConstraintSpaceBuilder builder(writing_direction.GetWritingMode(), writing_direction, false);
builder.SetAvailableSize(size);
builder.SetPercentageResolutionSize(size);
builder.SetInlineAutoBehavior(AutoSizeBehavior::kFitContent);
builder.SetFragmentainerBlockSize(fragmentainer_space_available);
builder.SetFragmentationType(FragmentationType::kFragmentColumn);
builder.SetShouldPropagateChildBreakValues();
ConstraintSpace space = builder.ToConstraintSpace();

// Finding target layout object
BlockNode box(To<LayoutBox>(document.getElementById(AtomicString("box"))->GetLayoutObject()));

// AdvanceToLayoutPhase
document.Lifecycle().AdvanceTo(DocumentLifecycle::kInStyleRecalc);
document.Lifecycle().AdvanceTo(DocumentLifecycle::kStyleClean);
document.Lifecycle().AdvanceTo(DocumentLifecycle::kInPerformLayout);

// Running layout algorithm
FragmentGeometry fragment_geometry = CalculateInitialFragmentGeometry(space, box);
const LayoutResult* result =
    BlockLayoutAlgorithm({box, fragment_geometry, space, To<BlockBreakToken>(break_token)})
        .Layout();

// Assertion
const PhysicalBoxFragment* fragment = result->GetPhysicalFragment();
EXPECT_EQ(PhysicalSize(30, 40), fragment->Size());
```

** `UpdateAllLifecyclePhasesForTest` is ..?
```cpp
bool LocalFrameView::UpdateAllLifecyclePhasesForTest() {
  AllowThrottlingScope allow_throttling(*this);
  bool result =
    GetFrame()
      .LocalFrameRoot()
      .View()
        ->UpdateLifecyclePhases(DocumentLifecycle::kPaintClean, DocumentUpdateReason::kTest);
  RunPostLifecycleSteps();
  return result;
}
```

** `LocalFrame` vs `LocalFrameView` is ..? (A frame can be either local or remote ..?)
** `Frame` vs `FrameView` is ..?
```markdown
CHATGPT:

> In summary, the Frame is the logical backbone of a frame,
> while the FrameView is its visual and layout counterpart.
> They work together to render and manage frames in Chromium.

| Aspect         | Frame                                   | FrameView                                |
|----------------|-----------------------------------------|------------------------------------------|
| **Role**       | Logical structure of a frame           | Visual and layout management of a frame  |
| **Scope**      | Manages frame content and behavior      | Manages frame's rendering and layout     |
| **Ownership**  | Owns the Document and scripting context | Owns visual elements and layout objects  |
| **Lifecycle**  | Tied to the frame's logical lifecycle   | Tied to the visual lifecycle and rendering |
| **Example Uses**| Handling navigation, security, and DOM | Handling scrolling, hit-testing, and painting |
```

** A document has a local frame and a local frame view view ..?

This `LocalFrameView` has a `LocalFrame` instance (returned by `GetFrame()`):
```cpp
// A LocalFrame is a frame hosted inside this process.
```

`LocalFrameRoot()` returns another `LocalFrame` instance:

```cpp
  // A local root is the root of a connected subtree that contains only
  // LocalFrames. The local root is responsible for coordinating input, layout,
  // et cetera for that subtree of frames.
  bool IsLocalRoot() const;
  LocalFrame& LocalFrameRoot() const;
```

`View()`, defined inside `LocalFrame` returns the `LocalFrameView` of the frame:
```cpp
LocalFrameView* View() const override;
```

Each of the local frame and the local frame view has its own lifecycle.
`UpdateLifecyclePhases` moves the frame view to the lifecycle step named: `DocumentLifecycle::kPaintClean`.

`UpdateLifecyclePhases()` takes a target step step as argument:

```cpp
bool LocalFrameView::UpdateLifecyclePhases(
    DocumentLifecycle::LifecycleState target_state,
    DocumentUpdateReason reason) {
  // ...

  // Only the following target states are supported.
  DCHECK(target_state == DocumentLifecycle::kLayoutClean ||
         target_state == DocumentLifecycle::kCompositingInputsClean ||
         target_state == DocumentLifecycle::kPrePaintClean ||
         target_state == DocumentLifecycle::kPaintClean);

  // ...
```

This function calls `LocalFrameView::UpdateLifecyclePhasesInternal` (many steps removed):

```cpp
void LocalFrameView::UpdateLifecyclePhasesInternal(
    DocumentLifecycle::LifecycleState target_state) {

  // Run style, layout, compositing and prepaint lifecycle phases and deliver
  // resize observations if required. Resize observer callbacks/delegates have
  // the potential to dirty layout (until loop limit is reached) and therefore
  // the above lifecycle phases need to be re-run until the limit is reached
  // or no layout is pending.
  // Note that after ResizeObserver has settled, we also run intersection
  // observations that need to be delievered in post-layout. This process can
  // also dirty layout, which will run this loop again.

  while (true) {
    bool run_more_lifecycle_phases = RunStyleAndLayoutLifecyclePhases(target_state);
    if (!run_more_lifecycle_phases)
      return;

    run_more_lifecycle_phases = RunCompositingInputsLifecyclePhase(target_state);
    if (!run_more_lifecycle_phases)
      return;

    run_more_lifecycle_phases = RunPrePaintLifecyclePhase(target_state);
    if (!run_more_lifecycle_phases)
      return;
  }

  RunPaintLifecyclePhase(PaintBenchmarkMode::kNormal);
}
```
** explain each step ..?

** It's a loop as some steps may make the layeut dirty and needs computation (maybe multiple times) before starting painting..?
** examples of dirtying the state..?

`RunStyleAndLayoutLifecyclePhases` internally calls:
```cpp
void LocalFrameView::UpdateStyleAndLayoutIfNeededRecursive() {
  UpdateStyleAndLayout();
  // ...
```
** explain `UpdateStyleAndLayoutIfNeededRecursive` ..? [HHERE??]

** `RunCompositingInputsLifecyclePhase` is ..?

** `RunPrePaintLifecyclePhase` is ..?

** `RunPaintLifecyclePhase` is ..?


To run the test, Chromium:
  * Prepares a dummy [document](https://dom.spec.whatwg.org/#concept-document)
  * Adds a simple DIV element to the body
  * Creates a `ConstraintSpace`
  * Calculates logical fragment (logical geometry of the DIV)
  * Runs the `BlockLayout` algorithm to transform it into a physical fragment
  * Checks the result size

A node instance exists for the `DIV` element before running the layouting algorthim.
** `getElementById` is ..?

** `AdvanceToLayoutPhase` is ..?

`FragmentGeometry` describe the logical sizes of the element:
```cpp
using LayoutUnit = FixedPoint<6, int32_t>;

// This struct is used for storing margins, borders or padding of a box on all four edges.
struct BoxStrut {
  // ...
  LayoutUnit inline_start;
  LayoutUnit inline_end;
  LayoutUnit line_over;
  LayoutUnit line_under;
};

// LogicalSize is the size of rect (typically a fragment) in the logical
// coordinate system.
// For more information about physical and logical coordinate systems, see:
// https://chromium.googlesource.com/chromium/src/+/main/third_party/blink/renderer/core/layout/README.md#coordinate-spaces
struct CORE_EXPORT LogicalSize {
  // ...

  LayoutUnit inline_size;
  LayoutUnit block_size;
};

// This represents the initial (pre-layout) geometry of a fragment. E.g.
//  - The inline-size of the fragment.
//  - The block-size of the fragment (might be |kIndefiniteSize| if height is 'auto' for example).
//  - The border, scrollbar, and padding.
// This *doesn't* necessarily represent the final geometry of the fragment.
struct FragmentGeometry {
  LogicalSize border_box_size;
  BoxStrut border;
  BoxStrut scrollbar;
  BoxStrut padding;
};
```

`CalculateInitialFragmentGeometry` is:

```cpp
FragmentGeometry CalculateInitialFragmentGeometry(
    const ConstraintSpace& space,
    const BlockNode& node,
    const BlockBreakToken* break_token,
    bool is_intrinsic) {

  MinMaxSizesFunctionRef min_max_sizes_func = [&](SizeType type) -> MinMaxSizesResult {
    return node.ComputeMinMaxSizes(space.GetWritingMode(), type, space);
  };

  const auto& style = node.Style();

  if (node.IsFrameSet()) {
    if (node.IsParentNGFrameSet()) {
      const auto size = space.AvailableSize();
      return {size, {}, {}, {}};
    }

    const auto size = node.InitialContainingBlockSize();
    return {size.ConvertToLogical(style.GetWritingMode()), {}, {}, {}};
  }

  const auto border = ComputeBorders(space, node);
  const auto padding = ComputePadding(space, style);
  auto scrollbar = ComputeScrollbars(space, node);

  const auto border_padding = border + padding;
  const auto border_scrollbar_padding = border_padding + scrollbar;

  if (node.IsReplaced()) {
    const auto border_box_size = ComputeReplacedSize(node, space, border_padding, ReplacedSizeMode::kNormal);
    return {border_box_size, border, scrollbar, padding};
  }

  const LayoutUnit inline_size = ComputeInlineSizeForFragment(space, node, border_padding, min_max_sizes_func);

  if (inline_size != kIndefiniteSize &&
      inline_size < border_scrollbar_padding.InlineSum() &&
      scrollbar.InlineSum() && !space.IsAnonymous()) [[unlikely]] {
    // Clamp the inline size of the scrollbar, unless it's larger than the
    // inline size of the content box, in which case we'll return that instead.
    // Scrollbar handling is quite bad in such situations, and this method here
    // is just to make sure that left-hand scrollbars don't mess up scrollWidth.
    // For the full story, visit http://crbug.com/724255.
    const auto content_box_inline_size =
        inline_size - border_padding.InlineSum();
    if (scrollbar.InlineSum() > content_box_inline_size) {
      if (scrollbar.inline_end) {
        scrollbar.inline_end = content_box_inline_size;
      } else {
        scrollbar.inline_start = content_box_inline_size;
      }
    }
  }

  const auto default_block_size = CalculateDefaultBlockSize(space, node, break_token, border_scrollbar_padding);
  const auto block_size = ComputeInitialBlockSizeForFragment(space, node, border_padding, default_block_size, inline_size);

  return {LogicalSize(inline_size, block_size), border, scrollbar, padding};
}
```
** explain this..?

`BlockLayoutAlgorithm` transform this logical fragment into a physical fragment:

`BlockLayoutAlgorithm` constructor is:
```cpp
// Constructor for algorithms that use BoxFragmentBuilder and
// BlockBreakToken.
explicit LayoutAlgorithm(const LayoutAlgorithmParams& params)
    : node_(To<InputNodeType>(params.node)),
      early_break_(params.early_break),
      container_builder_(
          params.node,
          &params.node.Style(),
          params.space,
          {params.space.GetWritingMode(), params.space.Direction()},
          params.break_token),
      additional_early_breaks_(params.additional_early_breaks) {

  container_builder_.SetIsNewFormattingContext(params.space.IsNewFormattingContext());
  container_builder_.SetInitialFragmentGeometry(params.fragment_geometry);

  if (params.space.HasBlockFragmentation() || IsBreakInside(params.break_token)) [[unlikely]] {
    SetupFragmentBuilderForFragmentation(params.space, params.node, params.break_token, &container_builder_);
  }
}


// ...

BlockLayoutAlgorithm::BlockLayoutAlgorithm(const LayoutAlgorithmParams& params) : LayoutAlgorithm(params),
      // ...
     {
  container_builder_.SetExclusionSpace(params.space.GetExclusionSpace());

  child_percentage_size_ = CalculateChildPercentageSize(      GetConstraintSpace(), Node(), ChildAvailableSize());
  replaced_child_percentage_size_ = CalculateReplacedChildPercentageSize(      GetConstraintSpace(), Node(), ChildAvailableSize(),      BorderScrollbarPadding(), BorderPadding());

  // If |this| is a list item, keep track of the unpositioned list marker in
  // |container_builder_|.
  if (const BlockNode marker_node = Node().ListMarkerBlockNodeIfListItem()) {
    if (ShouldPlaceUnpositionedListMarker() &&!marker_node.ListMarkerOccupiesWholeLine() && (!GetBreakToken() || GetBreakToken()->HasUnpositionedListMarker())) {
      container_builder_.SetUnpositionedListMarker(UnpositionedListMarker(marker_node));
    }
  }

  // Disable text box trimming if there's intervening border / padding.
  if (should_text_box_trim_node_start_ && BorderPadding().block_start != LayoutUnit()) {
    should_text_box_trim_node_start_ = false;
  }
  if (should_text_box_trim_node_end_ && BorderPadding().block_end != LayoutUnit()) {
    should_text_box_trim_node_end_ = false;
  }

  // Initialize `text-box-trim` flags from the `ComputedStyle`.
  const ComputedStyle& style = Node().Style();

  if (style.TextBoxTrim() != ETextBoxTrim::kNone) [[unlikely]] {
    should_text_box_trim_node_start_ |= style.ShouldTextBoxTrimStart();
    should_text_box_trim_node_end_ |= style.ShouldTextBoxTrimEnd();

    // Unless box-decoration-break is 'clone', box trimming specified inside a
    // fragmentation context will not apply at fragmentainer breaks in that
    // fragmentation context. Additionally, this is always disabled for
    // pagination, since our implementation is not able to paint outside the
    // page area.
    if (!GetConstraintSpace().HasBlockFragmentation() ||
        GetConstraintSpace().IsPaginated()) {
      should_text_box_trim_fragmentainer_start_ = false;
      should_text_box_trim_fragmentainer_end_ = false;
    } else {
      // Should only trim block-start at fragmentainer start if this node is
      // resumed after a break.
      if (IsBreakInside(GetBreakToken())) {
        should_text_box_trim_fragmentainer_start_ |=
            should_text_box_trim_node_start_;
      } else {
        should_text_box_trim_fragmentainer_start_ = false;
      }

      should_text_box_trim_fragmentainer_end_ |= should_text_box_trim_node_end_;

      if (!GetConstraintSpace().IsAnonymous() &&
          style.BoxDecorationBreak() != EBoxDecorationBreak::kClone) {
        should_text_box_trim_fragmentainer_start_ &=
            !style.ShouldTextBoxTrimStart();
        should_text_box_trim_fragmentainer_end_ &=
            !style.ShouldTextBoxTrimEnd();
      }
    }
  }
}
```

`BlockLayoutAlgorithm::Layout()` is:
```cpp
inline const LayoutResult* BlockLayoutAlgorithm::Layout(InlineChildLayoutContext* inline_child_layout_context) {
  container_builder_.SetIsInlineFormattingContext(inline_child_layout_context);

  // If this node has a column spanner inside, we'll force it to stay within the
  // current fragmentation flow, so that it doesn't establish a parallel flow,
  // even if it might have content that overflows into the next fragmentainer.
  // This way we'll prevent content that comes after the spanner from being laid
  // out *before* it.
  if (column_spanner_path_) {
    container_builder_.SetShouldForceSameFragmentationFlow();
  }

  const auto& constraint_space = GetConstraintSpace();
  container_builder_.SetBfcLineOffset(constraint_space.GetBfcOffset().line_offset);

  if (auto adjoining_object_types = constraint_space.GetAdjoiningObjectTypes()) {
    // If there were preceding adjoining objects, they will be affected when the
    // BFC block-offset gets resolved or updated. We then need to roll back and
    // re-layout those objects with the new BFC block-offset, once the BFC
    // block-offset is updated.
    abort_when_bfc_block_offset_updated_ = true;

    container_builder_.SetAdjoiningObjectTypes(adjoining_object_types);
  } else if (constraint_space.HasBlockFragmentation()) {
    // The offset from the block-start of the fragmentainer is part of the
    // constraint space, so if this offset changes, we need to abort.
    abort_when_bfc_block_offset_updated_ = true;
  }

  if (Style().HasAutoStandardLineClamp()) {
    if (!line_clamp_data_.data.IsLineClampContext()) {
      LayoutUnit clamp_bfc_offset = ChildAvailableSize().block_size;
      if (clamp_bfc_offset == kIndefiniteSize) {
        const MinMaxSizes sizes = ComputeInitialMinMaxBlockSizes(
            constraint_space, Node(), BorderPadding());
        if (sizes.max_size != LayoutUnit::Max()) {
          clamp_bfc_offset =
              (sizes.max_size - BorderScrollbarPadding().block_end)
                  .ClampNegativeToZero();
        }
      } else {
        clamp_bfc_offset =
            (BorderScrollbarPadding().block_start + clamp_bfc_offset)
                .ClampNegativeToZero();
      }
      line_clamp_data_.UpdateClampOffsetFromStyle(
          clamp_bfc_offset, BorderScrollbarPadding().block_start);
    }
  } else if (Style().HasLineClamp()) {
    if (!line_clamp_data_.data.IsLineClampContext()) {
      line_clamp_data_.UpdateLinesFromStyle(Style().LineClamp());
    }
  } else {
    if (Style().WebkitLineClamp() != 0) {
      UseCounter::Count(Node().GetDocument(),
                        WebFeature::kWebkitLineClampWithoutWebkitBox);
    }

    // If we're clamping by BFC offset, we need to subtract the bottom bmp to
    // leave room for it. This doesn't apply if we're relaying out to fix the
    // offset, because that already accounts for the bmp.
    if (line_clamp_data_.data.state ==
        LineClampData::kMeasureLinesUntilBfcOffset) {
      MarginStrut end_margin_strut = constraint_space.LineClampEndMarginStrut();
      end_margin_strut.Append(
          ComputeMarginsForSelf(constraint_space, Style()).block_end,
          /* is_quirky */ false);

      // `constraint_space.LineClampEndMarginStrut().Sum()` is the margin
      // contribution from our ancestor boxes, which has already been taken
      // into account for the clamp BFC offset that we have. We only need to
      // add any additional margin contribution from this box's margin.
      line_clamp_data_.data.clamp_bfc_offset -=
          BorderScrollbarPadding().block_end +
          (end_margin_strut.Sum() -
           constraint_space.LineClampEndMarginStrut().Sum());

      // The presence of borders and padding blocks margin propagation.
      if (!BorderScrollbarPadding().block_end) {
        line_clamp_data_.end_margin_strut = end_margin_strut;
      }
    }
  }

  LayoutUnit content_edge = BorderScrollbarPadding().block_start;

  PreviousInflowPosition previous_inflow_position = {
      LayoutUnit(), constraint_space.GetMarginStrut(),
      is_resuming_ ? LayoutUnit() : container_builder_.Padding().block_start,
      /* self_collapsing_child_had_clearance */ false};

  if (GetBreakToken()) {
    if (IsBreakInside(GetBreakToken()) && !GetBreakToken()->IsForcedBreak() &&
        !GetBreakToken()->IsCausedByColumnSpanner()) {
      // If the block container is being resumed after an unforced break,
      // margins inside may be adjoining with the fragmentainer boundary.
      previous_inflow_position.margin_strut.discard_margins = true;
    }

    if (GetBreakToken()->MonolithicOverflow()) {
      // If we have been pushed by monolithic overflow that started on a
      // previous page, we'll behave as if there's a valid breakpoint before the
      // first child here, and that it has perfect break appeal. This isn't
      // always strictly correct (the monolithic content in question may have
      // break-after:avoid, for instance), but should be a reasonable approach,
      // unless we want to make a bigger effort.
      has_break_opportunity_before_next_child_ = true;
    }
  }

  // Do not collapse margins between parent and its child if:
  //
  // A: There is border/padding between them.
  // B: This is a new formatting context
  // C: We're resuming layout from a break token. Margin struts cannot pass from
  //    one fragment to another if they are generated by the same block; they
  //    must be dealt with at the first fragment.
  //
  // In all those cases we can and must resolve the BFC block offset now.
  if (content_edge || is_resuming_ ||
      constraint_space.IsNewFormattingContext()) {
    bool discard_subsequent_margins =
        previous_inflow_position.margin_strut.discard_margins && !content_edge;
    if (!ResolveBfcBlockOffset(&previous_inflow_position)) {
      // There should be no preceding content that depends on the BFC block
      // offset of a new formatting context block, and likewise when resuming
      // from a break token.
      DCHECK(!constraint_space.IsNewFormattingContext());
      DCHECK(!is_resuming_);
      return container_builder_.Abort(LayoutResult::kBfcBlockOffsetResolved);
    }
    // Move to the content edge. This is where the first child should be placed.
    previous_inflow_position.logical_block_offset = content_edge;

    // If we resolved the BFC block offset now, the margin strut has been
    // reset. If margins are to be discarded, and this box would otherwise have
    // adjoining margins between its own margin and those subsequent content,
    // we need to make sure subsequent content discard theirs.
    if (discard_subsequent_margins)
      previous_inflow_position.margin_strut.discard_margins = true;
  }

  // If this node is a quirky container, (we are in quirks mode and either a
  // table cell or body), we set our margin strut to a mode where it only
  // considers non-quirky margins. E.g.
  // <body>
  //   <p></p>
  //   <div style="margin-top: 10px"></div>
  //   <h1>Hello</h1>
  // </body>
  // In the above example <p>'s & <h1>'s margins are ignored as they are
  // quirky, and we only consider <div>'s 10px margin.
  if (node_.IsQuirkyContainer())
    previous_inflow_position.margin_strut.is_quirky_container_start = true;

  // Try to reuse line box fragments from cached fragments if possible.
  // When possible, this adds fragments to |container_builder_| and update
  // |previous_inflow_position| and |BreakToken()|.
  const InlineBreakToken* previous_inline_break_token = nullptr;

  BlockChildIterator child_iterator(Node().FirstChild(), GetBreakToken());

  // If this layout is blocked by a display-lock, then we pretend this node has
  // no children and that there are no break tokens. Due to this, we skip layout
  // on these children.
  if (Node().ChildLayoutBlockedByDisplayLock())
    child_iterator = BlockChildIterator(BlockNode(nullptr), nullptr);

  BlockNode placeholder_child(nullptr);
  BlockChildIterator::Entry entry;
  for (entry = child_iterator.NextChild(); LayoutInputNode child = entry.node;
       entry = child_iterator.NextChild(previous_inline_break_token)) {
    const BreakToken* child_break_token = entry.token;

    if (child.IsOutOfFlowPositioned()) {
      // Out-of-flow fragmentation is a special step that takes place after
      // regular layout, so we should never resume anything here. However, we
      // may have break-before tokens, when a column spanner is directly
      // followed by an OOF.
      DCHECK(!child_break_token ||
             (child_break_token->IsBlockType() &&
              To<BlockBreakToken>(child_break_token)->IsBreakBefore()));
      HandleOutOfFlowPositioned(previous_inflow_position, To<BlockNode>(child));
    } else if (child.IsFloating()) {
      HandleFloat(previous_inflow_position, To<BlockNode>(child),
                  To<BlockBreakToken>(child_break_token));
    } else if (child.IsListMarker() && !child.ListMarkerOccupiesWholeLine()) {
      // Ignore outside list markers because they are already set to
      // |container_builder_.UnpositionedListMarker| in the constructor, unless
      // |ListMarkerOccupiesWholeLine|, which is handled like a regular child.
    } else if (child.IsColumnSpanAll() && constraint_space.IsInColumnBfc() &&
               constraint_space.HasBlockFragmentation()) {
      // The child is a column spanner. If we have no breaks inside (in parallel
      // flows), we now need to finish this fragmentainer, then abort and let
      // the column layout algorithm handle the spanner as a child. The
      // HasBlockFragmentation() check above may seem redundant, but this is
      // important if we're overflowing a clipped container. In such cases, we
      // won't treat the spanner as one, since we shouldn't insert any breaks in
      // that mode.
      DCHECK(!container_builder_.DidBreakSelf());
      DCHECK(!container_builder_.FoundColumnSpanner());
      DCHECK(!IsBreakInside(To<BlockBreakToken>(child_break_token)));

      if (constraint_space.IsPastBreak() ||
          container_builder_.HasInsertedChildBreak()) {
        // Something broke inside (typically in a parallel flow, or we wouldn't
        // be here). Before we can handle the spanner, we need to finish what
        // comes before it.
        container_builder_.AddBreakBeforeChild(child, kBreakAppealPerfect,
                                               /* is_forced_break */ true);

        // We're not ready to go back and lay out the spanner yet (see above),
        // so we don't set a spanner path, but since we did find a spanner, make
        // a note of it. This will make sure that we resolve our BFC block-
        // offset, so that we don't incorrectly appear to be self-collapsing.
        container_builder_.SetHasColumnSpanner(true);
        break;
      }

      // Establish a column spanner path. The innermost node will be the spanner
      // itself, wrapped inside the container handled by this layout algorithm.
      const auto* child_spanner_path =
          MakeGarbageCollected<ColumnSpannerPath>(To<BlockNode>(child));
      const auto* container_spanner_path =
          MakeGarbageCollected<ColumnSpannerPath>(Node(), child_spanner_path);
      container_builder_.SetColumnSpannerPath(container_spanner_path);

      // In order to properly collapse column spanner margins, we need to know
      // if the column spanner's parent was empty, for example, in the case that
      // the only child content of the parent since the last spanner is an OOF
      // that will get positioned outside the multicol.
      container_builder_.SetIsEmptySpannerParent(
          container_builder_.Children().empty() && is_resuming_);
      // After the spanner(s), we are going to resume inside this block. If
      // there's a subsequent sibling that's not a spanner, we're resume right
      // in front of that one. Otherwise we'll just resume after all the
      // children.
      for (entry = child_iterator.NextChild();
           LayoutInputNode sibling = entry.node;
           entry = child_iterator.NextChild()) {
        DCHECK(!entry.token);
        if (sibling.IsColumnSpanAll())
          continue;
        container_builder_.AddBreakBeforeChild(sibling, kBreakAppealPerfect,
                                               /* is_forced_break */ true);
        break;
      }
      break;
    } else if (child.IsTextControlPlaceholder()) {
      placeholder_child = To<BlockNode>(child);
    } else {
      // If this is the child we had previously determined to break before, do
      // so now and finish layout.
      if (early_break_ && IsEarlyBreakTarget(*early_break_, container_builder_,
                                             child)) [[unlikely]] {
        if (!ResolveBfcBlockOffset(&previous_inflow_position)) {
          // However, the predetermined breakpoint may be exactly where the BFC
          // block-offset gets resolved. If that hasn't yet happened, we need to
          // do that first and re-layout at the right BFC block-offset, and THEN
          // break.
          return container_builder_.Abort(
              LayoutResult::kBfcBlockOffsetResolved);
        }
        container_builder_.AddBreakBeforeChild(child, kBreakAppealPerfect,
                                               /* is_forced_break */ false);
        ConsumeRemainingFragmentainerSpace(&previous_inflow_position);
        break;
      }

      LayoutResult::EStatus status;
      if (child.CreatesNewFormattingContext()) {
        status = HandleNewFormattingContext(
            child, To<BlockBreakToken>(child_break_token),
            &previous_inflow_position);
        previous_inline_break_token = nullptr;
      } else {
        status = HandleInflow(
            child, child_break_token, &previous_inflow_position,
            inline_child_layout_context, &previous_inline_break_token);
      }

      if (status != LayoutResult::kSuccess) {
        // We need to abort the layout. No fragment will be generated.
        return container_builder_.Abort(status);
      }
      if (constraint_space.HasBlockFragmentation()) {
        // A child break in a parallel flow doesn't affect whether we should
        // break here or not.
        if (container_builder_.HasInflowChildBreakInside()) {
          // But if the break happened in the same flow, we'll now just finish
          // layout of the fragment. No more siblings should be processed.
          break;
        }
      }
    }
  }

  if (placeholder_child) {
    previous_inflow_position.logical_block_offset = HandleTextControlPlaceholder(placeholder_child, previous_inflow_position);
  }

  if (!child_iterator.NextChild(previous_inline_break_token).node) {
    // We've gone through all the children. This doesn't necessarily mean that
    // we're done fragmenting, as there may be parallel flows [1] (visible
    // overflow) still needing more space than what the current fragmentainer
    // can provide. It does mean, though, that, for any future fragmentainers,
    // we'll just be looking at the break tokens, if any, and *not* start laying
    // out any nodes from scratch, since we have started/finished all the
    // children, or at least created break tokens for them.
    //
    // [1] https://drafts.csswg.org/css-break/#parallel-flows
    container_builder_.SetHasSeenAllChildren();
  }

  // The intrinsic block size is not allowed to be less than the content edge
  // offset, as that could give us a negative content box size.
  intrinsic_block_size_ = content_edge;

  // To save space of the stack when we recurse into children, the rest of this
  // function is continued within |FinishLayout|. However it should be read as
  // one function.
  return FinishLayout(&previous_inflow_position, inline_child_layout_context);
}
```
** explain this ..?

Another test with update style from the same test suite is:
```cpp
// Verifies the collapsing margins case for the next pair:
// - bottom margin of a last in-flow child and bottom margin of its parent if
//   the parent has 'auto' computed height
TEST_F(BlockLayoutAlgorithmTest, CollapsingMarginsCase3) {
  SetBodyInnerHTML(R"HTML(
      <style>
       #container {
         margin-bottom: 20px;
       }
       #child {
         margin-bottom: 200px;
         height: 50px;
       }
      </style>
      <div id='container'>
        <div id='child'></div>
      </div>
    )HTML");

  const PhysicalBoxFragment* body_fragment = nullptr;
  const PhysicalBoxFragment* container_fragment = nullptr;
  const PhysicalBoxFragment* child_fragment = nullptr;
  const PhysicalBoxFragment* fragment = nullptr;
  auto run_test = [&](const Length& container_height) {
    UpdateStyleForElement(
        GetDocument().getElementById(AtomicString("container")),
        [&](ComputedStyleBuilder& builder) {
          builder.SetHeight(container_height);
        });
    fragment = GetHtmlPhysicalFragment();
    ASSERT_EQ(1UL, fragment->Children().size());
    body_fragment = To<PhysicalBoxFragment>(fragment->Children()[0].get());
    container_fragment =
        To<PhysicalBoxFragment>(body_fragment->Children()[0].get());
    ASSERT_EQ(1UL, container_fragment->Children().size());
    child_fragment =
        To<PhysicalBoxFragment>(container_fragment->Children()[0].get());
  };

  // height == auto
  run_test(Length::Auto());
  // Margins are collapsed with the result 200 = std::max(20, 200)
  // The fragment size 258 == body's margin 8 + child's height 50 + 200
  EXPECT_EQ(PhysicalSize(800, 258), fragment->Size());

  // height == fixed
  run_test(Length::Fixed(50));
  // Margins are not collapsed, so fragment still has margins == 20.
  // The fragment size 78 == body's margin 8 + child's height 50 + 20
  EXPECT_EQ(PhysicalSize(800, 78), fragment->Size());
}
```

# Rendering/Painting

We can study a test from `box_painter_test.cc`:

```cpp
// Preparing a Document
// document = dummy_page_holder_->frame_->DomWindow()->document()

// Both sets the inner html and runs the document lifecycle.
document.body()->setInnerHTML(R"HTML(
    <style>
      body {
        margin: 0;
        /* to force a subsequene and paint chunk */
        opacity: 0.5;
        /* to verify child empty backgrounds expand chunk bounds */
        height: 0;
      }
    </style>
    <div id="div1" style="width: 100px; height: 100px; background: green">
    </div>
    <div id="div2" style="width: 100px; height: 100px; outline: 2px solid blue">
    </div>
    <div id="div3" style="width: 200px; height: 150px"></div>
  )HTML", ASSERT_NO_EXCEPTION);
document.View()->UpdateAllLifecyclePhasesForTest();

auto* div1 = document.getElementById(AtomicString("div1"))->GetLayoutObject();
auto* div2 = document.getElementById(AtomicString("div2"))->GetLayoutObject();
auto* body = document.body()->GetLayoutBox();

// Empty backgrounds don't generate display items.
EXPECT_THAT(
    ContentDisplayItems(),
    ElementsAre(
      IsSameId(GetLayoutView().GetScrollableArea()->GetScrollingBackgroundDisplayItemClient().Id(), DisplayItem::kDocumentBackground),
      IsSameId(div1->Id(), DisplayItem::kBoxDecorationBackground),
      IsSameId(div2->Id(), DisplayItem::PaintPhaseToDrawingType(PaintPhase::kSelfOutlineOnly))
    )         
  );

EXPECT_THAT(
    ContentPaintChunks(),
    ElementsAre(VIEW_SCROLLING_BACKGROUND_CHUNK_COMMON,
                // Empty backgrounds contribute to bounds of paint chunks.
                IsPaintChunk(1, 3,
                              PaintChunk::Id(body->Layer()->Id(), DisplayItem::kLayerChunk),
                              body->FirstFragment().LocalBorderBoxProperties(),
                              nullptr, gfx::Rect(-2, 0, 202, 350))));
```

** `UpdateAllLifecyclePhasesForTest` is ..? (check preivous section)

# Render process / Painting

Check documentation at:
https://chromium.googlesource.com/chromium/src/+/main/third_party/blink/renderer/core/paint/README.md


> The primary responsibility of this directory is to convert the outputs from layout (the LayoutObject tree) to the inputs of the compositor (the cc::Layer list, which contains display items, and the associated cc::PropertyNodes).
>
> This process is done in the following document lifecycle phases:
>
>    PrePaint (kInPrePaint)
>        Paint invalidation which invalidates display items which need to be painted.
>        Builds paint property trees.
>    Paint (kInPaint)
>        Walks the LayoutObject tree and creates a display item list.
>        Groups the display list into paint chunks which share the same property tree state.
>        Commits the results to the compositor. * Decides which cc::Layers to create based on paint chunks. * Passes the paint chunks to the compositor in a cc::Layer list. * Converts the blink property tree nodes into cc property tree nodes.
>
>Debugging blink objects has information about dumping the paint and compositing datastructures for debugging.
>
> -- documentation link above

You can read about Chromium architecture here: https://www.chromium.org/developers/design-documents/multi-process-architecture/

> We refer to the main process that runs the UI and manages renderer and other processes as the "browser process" or "browser."
> Likewise, the processes that handle web content are called "renderer processes" or "renderers."
> The renderers use the Blink open-source layout engine for interpreting and laying out HTML.

> Each renderer process has one or more RenderFrame objects, which correspond to frames with documents containing content.
> The corresponding RenderFrameHost in the browser process manages state associated with that document

A renderer is
> In general, each new window or tab opens in a new process. The browser will spawn a new process and instruct
> it to create a single RenderFrame, which may create more iframes in the page (possibly in different processes).

The main initialization logic of a renderer is defined in: https://github.com/chromium/chromium/blob/main/content/renderer/renderer_main.cc#L144
** Do this function create a renderer or just init it ..?

This is the main logic of this function:

```cpp
// mainline routine for running as the Renderer process
int RendererMain(MainFunctionParams parameters) {
  InitializeSkia();

  RendererMainPlatformDelegate platform(parameters);

  base::PlatformThread::SetName("CrRendererMain");

  // Force main thread initialization. When the implementation is based on a
  // better means of determining which is the main thread, remove.
  RenderThread::IsMainThread();

  blink::Platform::InitializeBlink();
  std::unique_ptr<blink::scheduler::WebThreadScheduler> main_thread_scheduler =
      blink::scheduler::WebThreadScheduler::CreateMainThreadScheduler(base::MessagePump::Create(base::MessagePumpType::DEFAULT));

  platform.PlatformInitialize();

  content::ContentRendererClient* client = GetContentClient()->renderer();

  std::unique_ptr<RenderProcess> render_process = RenderProcessImpl::Create();
  // It's not a memory leak since RenderThread has the same lifetime
  // as a renderer process.
  base::RunLoop run_loop;
  new RenderThreadImpl(run_loop.QuitClosure(), std::move(main_thread_scheduler));

  if (client) {
    client->PostSandboxInitialized();
  }

  base::allocator::PartitionAllocSupport::Get()->ReconfigureAfterTaskRunnerInit(switches::kRendererProcess);

  run_loop.Run(); // RendererMain.START_MSG_LOOP

  platform.PlatformUninitialize();
  return 0;
}
```
** explain this..?

Back to the first code snipper, before creating the run loop, we have:

```cpp
  std::unique_ptr<RenderProcess> render_process = RenderProcessImpl::Create();
```

`RenderProcess` is:

```cpp
// A abstract interface representing the renderer end of the browser<->renderer
// connection. The opposite end is the RenderProcessHost. This is a singleton
// object for each renderer.
//
// RenderProcessImpl implements this interface for the regular browser.
// MockRenderProcess implements this interface for certain tests, especially
// ones derived from RenderViewTest.
class RenderProcess : public ChildProcess {
```

`Create` is a static method that creates `new RenderProcessImpl()`.
In its constructor, this class set some v8 flags.

The Render process interface does not have logical methods other than those
inherited from `ChildProcess`.
** The process acts as a ..?

The first code snippet also contains:

```cpp
  RendererMainPlatformDelegate platform(parameters);
  // ...
  platform.PlatformInitialize();
```

`RendererMainPlatformDelegate` is a class with two methods:

```cpp
  // Called first thing and last thing in the process' lifecycle, i.e. before
  // the sandbox is enabled.
  void PlatformInitialize();
  void PlatformUninitialize();
```

Each platform has its implementation of it, for linux, it's defined under
`content/renderer/renderer_main_platform_delegate_linux.cc`.

** a render-thread is ..? it does ..?

The main logic of render thread imp`RenderThreadImpl` is:

```cpp
void RenderThreadImpl::Init() {
  GetContentClient()->renderer()->PostIOThreadCreated(GetIOTaskRunner().get());

  // NOTE: Do not add interfaces to |binders| within this method. Instead, modify the definition of |ExposeRendererInterfacesToBrowser()| to ensure security review coverage.
  mojo::BinderMap binders;
  InitializeWebKit(&binders);

  GetContentClient()->renderer()->RenderThreadStarted();
  ExposeRendererInterfacesToBrowser(weak_factory_.GetWeakPtr(), &binders);
  ExposeInterfacesToBrowser(std::move(binders));

  GetAssociatedInterfaceRegistry()->AddInterface<mojom::Renderer>(
    base::BindRepeating(&RenderThreadImpl::OnRendererInterfaceReceiver, base::Unretained(this))
  );
}
```
** explain this..?


> WebKit and Blink have a shared history, as Blink was forked from WebKit by Google in 2013.
> Therefore, they share many architectural similarities, especially in terms of their layout
> and rendering processes.
> In summary, WebKit, like Blink, implements more than just the painting step.
> It encompasses various stages involved in rendering web content, including layout, rendering, and compositing.

`InitializeWebKit` is essentially:

```cpp
void RenderThreadImpl::InitializeWebKit(mojo::BinderMap* binders) {
  blink_platform_impl_ = std::make_unique<RendererBlinkPlatformImpl>(main_thread_scheduler_.get());

  blink::Initialize(blink_platform_impl_.get(), binders, main_thread_scheduler_.get());

  blink_platform_impl_->CreateAndSetCompositorThread();
  compositor_task_runner_ = blink_platform_impl_->CompositorThreadTaskRunner();

  compositor_task_runner_->PostTask(FROM_HERE, base::BindOnce(&base::DisallowBlocking));
  GetContentClient()->renderer()->PostCompositorThreadCreated(compositor_task_runner_.get());

  RenderThreadImpl::RegisterSchemes();

  RenderMediaClient::Initialize();
}
```

First, it creates an instance of `RendererBlinkPlatformImpl`.
The latter constructor gets an instance of `blink::scheduler::WebThreadScheduler`.
** `MainThreadSchedulerImpl` vs `blink::scheduler::WebThreadScheduler` is ..?
`MainThreadSchedulerImpl` extends `WebThreadScheduler`:
```cpp
class PLATFORM_EXPORT MainThreadSchedulerImpl
    : public ThreadSchedulerBase,
      public MainThreadScheduler,
      public WebThreadScheduler,
      public IdleHelper::Delegate,
      public RenderWidgetSignals::Observer,
      public base::trace_event::TraceLog::AsyncEnabledStateObserver {
```
** what are other replacemetns for `MainThreadSchedulerImpl`..?
`main_thread_scheduler_` is defined as:
```cpp
  // These objects live solely on the render thread.
  std::unique_ptr<blink::scheduler::WebThreadScheduler> main_thread_scheduler_;
  std::unique_ptr<RendererBlinkPlatformImpl> blink_platform_impl_;
```
it's passed to `RenderThreadImpl` constructor.
It's created by `blink::scheduler::WebThreadScheduler::CreateMainThreadScheduler(CreateMainThreadMessagePump())` above.

The location of the modules we use:
 * inside `third_party/blink`: `MainThreadSchedulerImpl`, `WebThreadScheduler`
 * inside `content/renderer`: `RendererBlinkPlatformImpl`, `BlinkPlatformImpl`, `RenderThreadImpl`, `RenderProcess`

`RendererBlinkPlatformImpl` extends `BlinkPlatformImpl`.
** what's the difference between them..?
Inside the constructor of `RendererBlinkPlatformImpl` do some initialization and runs:

```cpp
  GetIOTaskRunner()->PostTask(
    FROM_HERE,
    base::BindOnce(
      [](base::PlatformThreadId* id, base::WaitableEvent* io_thread_id_ready_event) {
        *id = base::PlatformThread::CurrentId();
        io_thread_id_ready_event->Signal();
      },
      &io_thread_id_, &io_thread_id_ready_event_
    )
  );
```

The `IOTaskRunner` here is the same one passed to `PostIOThreadCreated` above.
It's defined in `ChildThreadImpl`, extended by `RenderThreadImpl`:
```cpp
scoped_refptr<base::SingleThreadTaskRunner> ChildThreadImpl::GetIOTaskRunner() {
  if (IsInBrowserProcess())
    return browser_process_io_runner_;
  return ChildProcess::current()->io_task_runner();
}

bool ChildThreadImpl::IsInBrowserProcess() const {
  return static_cast<bool>(browser_process_io_runner_);
}
```

`RenderProcess` extends `ChildProcess`. Thus `ChildProcess::current()` returns the render process.

And `io_task_runner` is defined as:

```cpp
base::SingleThreadTaskRunner* io_task_runner() {
  return io_thread_->task_runner().get();
}

// ...

// The thread that handles IO events.
std::unique_ptr<base::Thread> io_thread_;
```

This thread is initialized inside `ChildProcess` constructor to an instance of `ChildIOThread`.

```cpp
class ChildIOThread : public base::Thread {
```

** usages of the IO thread are ..? other usages of `ChildIOThread` than this ..?

`task_runner` is defined is `base::Thread`:

```cpp
  // Returns a TaskRunner for this thread. Use the TaskRunner's PostTask
  // methods to execute code on the thread. Returns nullptr if the thread is not
  // running (e.g. before Start or after Stop have been called). Callers can
  // hold on to this even after the thread is gone; in this situation, attempts
  // to PostTask() will fail.
  //
  // In addition to this Thread's owning sequence, this can also safely be
  // called from the underlying thread itself.
  scoped_refptr<SingleThreadTaskRunner> task_runner() const {
    // This class doesn't provide synchronization around |message_loop_base_|
    // and as such only the owner should access it (and the underlying thread
    // which never sees it before it's set). In practice, many callers are
    // coming from unrelated threads but provide their own implicit (e.g. memory
    // barriers from task posting) or explicit (e.g. locks) synchronization
    // making the access of |message_loop_base_| safe... Changing all of those
    // callers is unfeasible; instead verify that they can reliably see
    // |message_loop_base_ != nullptr| without synchronization as a proof that
    // their external synchronization catches the unsynchronized effects of
    // Start().
    DCHECK(owning_sequence_checker_.CalledOnValidSequence() ||
           (id_event_.IsSignaled() && id_ == PlatformThread::CurrentId()) ||
           delegate_);
    return delegate_ ? delegate_->GetDefaultTaskRunner() : nullptr;
  }
```

`delegate_` is defined by:

```cpp
// The thread's Delegate and RunLoop are valid only while the thread is
// alive. Set by the created thread.
std::unique_ptr<Delegate> delegate_;
```

It's initialized as:

```cpp
  if (options.delegate) {
    DCHECK(!options.message_pump_factory);
    delegate_ = std::move(options.delegate);
  } else if (options.message_pump_factory) {
    delegate_ = std::make_unique<internal::SequenceManagerThreadDelegate>(
        MessagePumpType::CUSTOM, options.message_pump_factory);
  } else {
    delegate_ = std::make_unique<internal::SequenceManagerThreadDelegate>(
        options.message_pump_type,
        BindOnce([](MessagePumpType type) { return MessagePump::Create(type); },
                 options.message_pump_type));
  }
```
** explain this ..? what's the type of `options.delegate`..?

Inside `SequenceManagerThreadDelegate`, `GetDefaultTaskRunner` is defined as:
```cpp
  scoped_refptr<SingleThreadTaskRunner> GetDefaultTaskRunner() override {
    // Surprisingly this might not be default_task_queue_->task_runner() which
    // we set in the constructor. The Thread::Init() method could create a
    // SequenceManager on top of the current one and call
    // SequenceManager::SetDefaultTaskRunner which would propagate the new
    // TaskRunner down to our SequenceManager. Turns out, code actually relies
    // on this and somehow relies on
    // SequenceManagerThreadDelegate::GetDefaultTaskRunner returning this new
    // TaskRunner. So instead of returning default_task_queue_->task_runner() we
    // need to query the SequenceManager for it.
    // The underlying problem here is that Subclasses of Thread can do crazy
    // stuff in Init() but they are not really in control of what happens in the
    // Thread::Delegate, as this is passed in on calling StartWithOptions which
    // could happen far away from where the Thread is created. We should
    // consider getting rid of StartWithOptions, and pass them as a constructor
    // argument instead.
    return sequence_manager_->GetTaskRunner();
  }
```
** explain this..?

`Run` defined on `ChildIOThread` is:
```cpp
void Run(base::RunLoop* run_loop) override {
```
** where does it get the instance of `run_loop` from ..?

Back to the constructor of `RendererBlinkPlatformImpl`, this code:

```cpp
  GetIOTaskRunner()->PostTask(
    FROM_HERE,
    base::BindOnce(
      [](base::PlatformThreadId* id, base::WaitableEvent* io_thread_id_ready_event) {
        *id = base::PlatformThread::CurrentId();
        io_thread_id_ready_event->Signal();
      },
      &io_thread_id_, &io_thread_id_ready_event_
    )
  );
```
** are we using `ThreadControllerImpl::GetDefaultTaskRunner`, `ThreadControllerWithMessagePumpImpl::GetDefaultTaskRunner`,
    `Thread::Delegate ..... GetDefaultTaskRunner`.., or `CONTENT_EXPORT Handle .... GetDefaultTaskRunner`?
** explain this ..? who is exactly the sequence manager used..? `PostTask` is ..?

** Back to `RenderThreadImpl::Init` above, after `InitializeWebKit` ..?
```cpp
  GetContentClient()->renderer()->RenderThreadStarted();
  ExposeRendererInterfacesToBrowser(weak_factory_.GetWeakPtr(), &binders);
  ExposeInterfacesToBrowser(std::move(binders));

  GetAssociatedInterfaceRegistry()->AddInterface<mojom::Renderer>(
    base::BindRepeating(&RenderThreadImpl::OnRendererInterfaceReceiver, base::Unretained(this))
  );
```
** explain bindings..? their usages..?

The documentation of `mojo::BinderMap` says:
```cpp
// BinderMapWithContext is a helper class that maintains a registry of
// callbacks that bind receivers for arbitrary Mojo interfaces. By default the
// map is empty and cannot bind any interfaces.
```

# Blink

Back to the initial code snippet, `blink::Platform::InitializeBlink()` initializes Blink.
The documentation of `InitializeBlink` says:

```cpp
  // Initialize platform and wtf. If you need to initialize the entire Blink,
  // you should use blink::Initialize. WebThreadScheduler must be owned by
  // the embedder. InitializeBlink must be called before WebThreadScheduler is
  // created and passed to InitializeMainThread.
  static void InitializeBlink();
```

The creation of the web thread scheduler follows:
```cpp
  std::unique_ptr<blink::scheduler::WebThreadScheduler> main_thread_scheduler =
      blink::scheduler::WebThreadScheduler::CreateMainThreadScheduler(base::MessagePump::Create(base::MessagePumpType::DEFAULT));
```
** how is it "passed to InitializeMainThread"..?

The implementation of `InitializeBlink` is:

```cpp
  void Platform::InitializeBlink() {
    DCHECK(!did_initialize_blink_);
    WTF::Partitions::Initialize();
    WTF::Initialize();
    Length::Initialize();
    ProcessHeap::Init();
    ThreadState::AttachMainThread();
    did_initialize_blink_ = true;
  }
```

# DOM and style

** `third_party/blink/renderer/core/dom/` is ..? (short summary) ..?

** `third_party/blink/renderer/core/style/` is ..? (short summary) ..?

# Message loop

## Starting the message loop

** The `RunLoop` is..?

The definition of `Run` says:

```cpp
  // Run the current RunLoop::Delegate. This blocks until Quit is called
  // (directly or by running the RunLoop::QuitClosure).
  void Run(const Location& location = Location::Current());
```
** `Location::Current()` is ..?

`Run` mainly calls `delegate_->Run(application_tasks_allowed, TimeDelta::Max());`

`Delegate` documentation says:

```cpp
  // A RunLoop::Delegate is a generic interface that allows RunLoop to be
  // separate from the underlying implementation of the message loop for this
  // thread. It holds private state used by RunLoops on its associated thread.
  // One and only one RunLoop::Delegate must be registered on a given thread
  // via RunLoop::RegisterDelegateForCurrentThread() before RunLoop instances
  // and RunLoop static methods can be used on it.
  class BASE_EXPORT Delegate {

    // ...

    // Used by RunLoop to inform its Delegate to Run/Quit. Implementations are
    // expected to keep on running synchronously from the Run() call until the
    // eventual matching Quit() call or a delay of |timeout| expires. Upon
    // receiving a Quit() call or timing out it should return from the Run()
    // call as soon as possible without executing remaining tasks/messages.
    // Run() calls can nest in which case each Quit() call should result in the
    // topmost active Run() call returning. The only other trigger for Run()
    // to return is the |should_quit_when_idle_callback_| which the Delegate
    // should probe before sleeping when it becomes idle.
    // |application_tasks_allowed| is true if this is the first Run() call on
    // the stack or it was made from a nested RunLoop of
    // Type::kNestableTasksAllowed (otherwise this Run() level should only
    // process system tasks).
    virtual void Run(bool application_tasks_allowed, TimeDelta timeout) = 0;
```

The delegate must be attached before calling ??:

```cpp
// Helper class to run the RunLoop::Delegate associated with the current thread.
// A RunLoop::Delegate must have been bound to this thread (ref.
// RunLoop::RegisterDelegateForCurrentThread()) prior to using any of RunLoop's
// member and static methods unless explicitly indicated otherwise (e.g.
// IsRunning/IsNestedOnCurrentThread()). RunLoop::Run can only be called once
// per RunLoop lifetime. Create a RunLoop on the stack and call Run/Quit to run
// a nested RunLoop but please avoid nested loops in production code!
```

A delegate is
```cpp
  // A RunLoop::Delegate is a generic interface that allows RunLoop to be
  // separate from the underlying implementation of the message loop for this
  // thread. It holds private state used by RunLoops on its associated thread.
  // One and only one RunLoop::Delegate must be registered on a given thread
  // via RunLoop::RegisterDelegateForCurrentThread() before RunLoop instances
  // and RunLoop static methods can be used on it.
```

** where do we call `RegisterDelegateForCurrentThread` to bind a delegate to the run_loop run ..?

This is the constructor of `RunLoop`:

```cpp
ABSL_CONST_INIT thread_local RunLoop::Delegate* delegate = nullptr;

RunLoop::RunLoop(Type type)
    : delegate_(delegate),
      type_(type),
      origin_task_runner_(SingleThreadTaskRunner::GetCurrentDefault()) {
  DCHECK(delegate_) << "A RunLoop::Delegate must be bound to this thread prior "
                       "to using RunLoop.";
  DCHECK(origin_task_runner_);
}
```

## Creating the message loop delegate

As you can see inside `RendererMain` :
```cpp
  std::unique_ptr<blink::scheduler::WebThreadScheduler> main_thread_scheduler =
      blink::scheduler::WebThreadScheduler::CreateMainThreadScheduler(base::MessagePump::Create(base::MessagePumpType::DEFAULT));
```
** a `class BASE_EXPORT MessagePumpDefault : public MessagePump` is ..?

The message pump used is `MessagePumpDefault`.

** a `ThreadScheduler` is ..? a `MainThreadScheduler` is ..?

The main thread scheduler is created with:
```cpp
  auto sequence_manager =
      message_pump
          ? base::sequence_manager::
                CreateSequenceManagerOnCurrentThreadWithPump(
                    std::move(message_pump), std::move(settings))
          : base::sequence_manager::CreateSequenceManagerOnCurrentThread(
                std::move(settings));
  return std::make_unique<MainThreadSchedulerImpl>(std::move(sequence_manager));
```

** A `SequenceManager` is ..? the difference between a sequence manager and the `MainThreadSchedulerImpl` is ..?

`CreateSequenceManagerOnCurrentThreadWithPump` is:
```cpp
std::unique_ptr<SequenceManager> CreateSequenceManagerOnCurrentThreadWithPump(
    std::unique_ptr<MessagePump> message_pump,
    SequenceManager::Settings settings) {
  std::unique_ptr<SequenceManager> manager =
      internal::SequenceManagerImpl::CreateUnbound(std::move(settings));
  manager->BindToMessagePump(std::move(message_pump));
  return manager;
}
```

`SequenceManagerImpl::CreateUnbound` is:
```cpp
std::unique_ptr<SequenceManagerImpl> SequenceManagerImpl::CreateUnbound(
    SequenceManager::Settings settings) {
  auto thread_controller =
      ThreadControllerWithMessagePumpImpl::CreateUnbound(settings);
  return WrapUnique(new SequenceManagerImpl(std::move(thread_controller),
                                            std::move(settings)));
}
```

** A `ThreadController` is ..?

** `ThreadController` vs `ThreadControllerWithMessagePumpImpl` is ..?

`createUnbound` here just returns `new ThreadControllerWithMessagePumpImpl(settings))`.

` manager->BindToMessagePump(std::move(message_pump))` is ..?

As `manager` an instance of `SequenceManagerImpl`, that call is:

```cpp
void SequenceManagerImpl::BindToMessagePump(std::unique_ptr<MessagePump> pump) {
  controller_->BindToCurrentThread(std::move(pump));
  CompleteInitializationOnBoundThread();
}
```

`pump` is `message_pump` created earlier.
`controller_` is `thread_controller` created earlier,
which is the value returned by `ThreadControllerWithMessagePumpImpl::CreateUnbound`.

`controller_->BindToCurrentThread(std::move(pump))` registers itself as the delegate:
```cpp
  RunLoop::RegisterDelegateForCurrentThread(this);
```

This is how the run loop delegate is attached.
Later, when we create a run loop, this is the delegate that'll be `Run` when
the run loop starts.

## How the message loop works

Back again to `_delegate->Run...` above, that method is `ThreadControllerWithMessagePumpImpl::Run`.
The latter manages loop ending ..?
then, it calls `_pump->Run(this)`.

`_pump` is `message_pump` created preivously.
It defines a `Run` method with a loop:

```cpp
  for (;;) {
    Delegate::NextWorkInfo next_work_info = delegate->DoWork();
    bool has_more_immediate_work = next_work_info.is_immediate();
    if (!keep_running_)
      break;

    if (has_more_immediate_work)
      continue;

    has_more_immediate_work = delegate->DoIdleWork();
    if (!keep_running_)
      break;

    if (has_more_immediate_work)
      continue;

    if (next_work_info.delayed_run_time.is_max()) {
      event_.Wait();
    } else {
      event_.TimedWait(next_work_info.remaining_delay());
    }
    // Since event_ is auto-reset, we don't need to do anything special here
    // other than service each delegate method.
  }
```
** explain this..?
** what to do if message queue?? is empty ..?

**`Delegate::NextWorkInfo` is ..?

It calls `delegate->DoWork()` at the beginning of the iteration.
The delegate is the thread controller with the message pump.
It defines a method `DoWork`.

** `ThreadControllerWithMessagePumpImpl::DoWork()` is ..?

** `absl::optional<WakeUp> ThreadControllerWithMessagePumpImpl::DoWorkImpl` is ..?

The main logic if this is getting and running the next task (?? takS):

```cpp
absl::optional<SequencedTaskSource::SelectedTask> selected_task =
    main_thread_only().task_source->SelectNextTask(lazy_now_select_task,
                                                    select_task_option);

task_annotator_.RunTask(
    "ThreadControllerImpl::RunTask", selected_task->task,
    [&selected_task, &source](perfetto::EventContext& ctx) {
      if (selected_task->task_execution_trace_logger) {
        selected_task->task_execution_trace_logger.Run(
            ctx, selected_task->task);
      }
      source->MaybeEmitTaskDetails(ctx, selected_task.value());
    });
```
** explain these..?


The thread controller task source is set by `SequenceManagerImpl` constructor:

```cpp
controller_->SetSequencedTaskSource(this);
```

The method is defined as:

```cpp
absl::optional<SequenceManagerImpl::SelectedTask>
SequenceManagerImpl::SelectNextTask(LazyNow& lazy_now,
                                    SelectTaskOption option) {
  absl::optional<SelectedTask> selected_task =
      SelectNextTaskImpl(lazy_now, option);

  return selected_task;
}
```
** explain this..?
** `SelectNextTaskImpl` is ..? it does ..?

The main line for picking the task is:
```cpp
    ExecutingTask& executing_task =
        *main_thread_only().task_execution_stack.rbegin();
```

`main_thread_only` is created in `SequenceManagerImpl` as:
```cpp
main_thread_only_(this, associated_thread_, settings_, settings_.clock),
```

`main_thread_only().task_execution_stack` is
```cpp
std::deque<ExecutingTask> task_execution_stack;
```

** `ExecutingTask` is ..?

## Adding tasks to the massage loop

Adding tasks to the stack is managed (only here??) (why is it only the manager..?)
by the sequence manager:
```cpp

main_thread_only().task_execution_stack.emplace_back(
    work_queue->TakeTaskFromWorkQueue(), work_queue->task_queue(),
    InitializeTaskTiming(work_queue->task_queue()));
```
** explain this..? why is it here..?

`work_queue` is:
```cpp
internal::WorkQueue* work_queue =
    main_thread_only().selector.SelectWorkQueueToService(option);
```
** explain this..?

`main_thread_only().selector` is:
```cpp
internal::TaskQueueSelector selector;
```

It's initialized inside `SequenceManagerImpl` constructor:
```cpp
main_thread_only().selector.SetTaskQueueSelectorObserver(this);
```

A queue from two queues sets can be returned:
```cpp
WorkQueueSets delayed_work_queue_sets_;
WorkQueueSets immediate_work_queue_sets_;
```

Queues are added by the sequence manager `SequenceManagerImpl::CreateTaskQueueImpl`:
```cpp
std::unique_ptr<internal::TaskQueueImpl>
SequenceManagerImpl::CreateTaskQueueImpl(const TaskQueue::Spec& spec) {
  // ....
  std::unique_ptr<internal::TaskQueueImpl> task_queue =
      std::make_unique<internal::TaskQueueImpl>(
          this,
          spec.non_waking ? main_thread_only().non_waking_wake_up_queue.get()
                          : main_thread_only().wake_up_queue.get(),
          spec);
  main_thread_only().active_queues.insert(task_queue.get());
  main_thread_only().selector.AddQueue(
      task_queue.get(), settings().priority_settings.default_priority());
  return task_queue;
}
```

** `CreateTaskQueue` that adds a queue is called by ..?

** `TaskAnnotator::RunTaskImpl` is ..?

It mainly runs the task:
```cpp
std::move(pending_task.task).Run();
```

`pending_task.task` is:
```cpp
// The task to run.
  OnceClosure task;
```

