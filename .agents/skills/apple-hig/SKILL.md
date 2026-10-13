---
name: apple-hig
description: Apply Apple's complete Human Interface Guidelines across iOS, iPadOS, macOS, tvOS, visionOS, watchOS, and games. Use for Apple-platform product design, UI implementation, or design review; route to the relevant HIG topics and platform-specific guidance.
---

# Apple Human Interface Guidelines

Use the [live HIG](https://developer.apple.com/design/human-interface-guidelines/) as the source of truth. This skill covers the complete HIG navigation, not only iOS: Getting started, Foundations, Patterns, Components, Inputs, and Technologies. The [topic map](references/topic-map.md) indexes all 158 topic pages and their substantive subsection anchors as observed on October 8, 2026. HIG guidance changes; check the current page, platform considerations, specifications, resources, and change log when making a decision.

## Apply the guidance

1. Identify the product, platform(s), device sizes, input methods, and task. For cross-platform work, use [platform lenses](references/platform-lenses.md) to identify each applicable “Designing for…” page in the topic map. Treat a platform-specific section as the authority for that platform; avoid carrying iPhone conventions to Mac, TV, Watch, or spatial interfaces without checking.
2. Start with [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles) and the relevant Foundations. Then look up the user journey in Patterns, the UI elements in Components, the interaction methods in Inputs, and any integrated service in Technologies. Search the topic map for the exact topic and subsection. Section IDs in the map append to the page URL after `#`.
3. Read the **entire applicable HIG page**, including its examples, images, tables, platform considerations, specifications, and linked related resources. Follow a linked Apple API or design resource when the implementation detail depends on it. The index is a route to guidance, not a substitute for the page.
4. Apply the guidance to the actual design or code. Prefer familiar system behaviors and components; customize with a reason tied to the product. Account for accessibility, localization and right-to-left layout, privacy, appearance modes, dynamic sizing, motion preferences, and the platform's input model where relevant.
5. In reviews, state the concrete issue, affected platform/context, the Apple source, and an actionable fix. Distinguish Apple's guidance from your own design judgment. Verify behavior on the target OS/device or preview when possible; do not claim HIG compliance from code inspection alone.

## Decisions to make explicitly

- **Hierarchy and navigation:** Select patterns that fit content depth and platform conventions. Check the relevant pages for tab bars, sidebars, split views, toolbars, menus, windows, sheets, and search rather than assuming one navigation system works everywhere.
- **Content and visual system:** Check layout, typography, color, materials, icons/SF Symbols, images, motion, writing, and app icons. Use the system's adaptive behavior where it serves the experience; consult current HIG specifications before using fixed dimensions or colors.
- **Accessibility and inclusion:** Check vision, hearing, mobility, speech, and cognitive needs; evaluate focus, labels, alternate input, readable text, contrast, reduced motion, and non-color cues in the actual interface.
- **Trust and feedback:** Check privacy, permission timing, loading, errors, undo, account management, notifications, and feedback for the flow being built. Explain irreversible or sensitive actions clearly.
- **Specialized surfaces:** Use the dedicated topic for widgets, Live Activities, complications, controls, CarPlay, Apple Pay, SharePlay, Siri, spatial experiences, and other technologies. These have their own anatomy and platform requirements.

## Source navigation

Read [references/topic-map.md](references/topic-map.md) for the complete topic and subsection inventory. Search it by feature name, component, platform, or anchor; then open the corresponding live Apple page. If a page is unavailable through text-only browsing because Apple's documentation requires JavaScript, use a browser that renders the site. Check the page's linked “Resources” for related HIG topics, developer documentation, videos, and design assets when those are relevant to the task. Do not turn an illustrative example or older fixed metric into a universal requirement without checking the current page and platform.
