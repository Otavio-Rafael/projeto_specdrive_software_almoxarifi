---
name: Nexus StorageControl Design System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3d494a'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6d797b'
  outline-variant: '#bcc9ca'
  surface-tint: '#006972'
  primary: '#006972'
  on-primary: '#ffffff'
  primary-container: '#48b8c5'
  on-primary-container: '#00454c'
  inverse-primary: '#6ad6e3'
  secondary: '#565e74'
  on-secondary: '#ffffff'
  secondary-container: '#dae2fd'
  on-secondary-container: '#5c647a'
  tertiary: '#006c49'
  on-tertiary: '#ffffff'
  tertiary-container: '#22c087'
  on-tertiary-container: '#00482f'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8df2ff'
  primary-fixed-dim: '#6ad6e3'
  on-primary-fixed: '#001f23'
  on-primary-fixed-variant: '#004f56'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  data-tabular:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.875rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies a clean, precise, and highly dependable corporate ERP & SaaS aesthetic tailored for enterprise-grade inventory and departmental supply management. The visual language balances industrial operational efficiency with contemporary software elegance.

### Personality & Emotional Response
- **Operational Rigor & Reliability:** Gives inventory managers, procurement officers, and departmental leads complete peace of mind through clean data structure, high scannability, and instant state feedback.
- **Modern Fluidity:** Replaces heavy legacy enterprise software friction with an airy, deliberate, and high-performance workflow.
- **Predictive Vigilance:** Immediate, low-fatigue peripheral awareness through a calibrated alert spectrum (from stable shelf-life to critical stock-outs and shelf expirations).

### Design Movement
- **Corporate / Modern High-Density SaaS:** Grounded in a structured 8px baseline, subtle crisp micro-borders, restrained depth layers, and ergonomic density that accommodates complex tabular data without cognitive overload.

## Colors

The palette derives directly from the clean teal-cyan brand mark, paired with deep slate-navy structural anchors and precise functional indicators.

### Palette Architecture
- **Primary (`#48B8C5`):** The signature teal-cyan from the brand mark. Used for key interactive highlights, primary button fills, active tabs, selected states, and focused rings.
- **Secondary (`#0F172A` / `#1E293B`):** Deep corporate slate. Powers persistent navigation bars, sidebars, dense data table headers, and primary high-contrast typography.
- **Functional Semantics:**
  - **Success / Inbound (`#10B981`):** Emerald green for stock check-in, valid expiration thresholds (>30 days), positive variance, and batch approvals.
  - **Warning / Expiry Tiers:**
    - *Early Warning (30d):* `#F59E0B` (Amber) for routine renewal reminders.
    - *Imminent Risk (15d):* `#F97316` (Orange) for fast-track consumption items.
    - *Urgent Window (5d):* `#EA580C` (Deep Coral/Orange) for critical shelf-life warnings.
  - **Danger / Critical (`#EF4444`):** Pure crimson for expired batches, negative stock, and quarantine locks.
- **Neutrals & Surfaces:**
  - Canvas Background: `#F8FAFC` (Slate 50)
  - Surface Card: `#FFFFFF`
  - Border Subdued: `#E2E8F0` (Slate 200)
  - Text Primary: `#0F172A` (Slate 900)
  - Text Secondary: `#64748B` (Slate 500)

## Typography

The typographic hierarchy pairs **Plus Jakarta Sans** for clear, modern section titles and metrics displays with **Inter** for dense operational readouts, tables, batch forms, and interface labels.

### Rules & Formatting
- Numeric representations in data grids, SKU displays, quantities, and expiration dates must enable OpenType tabular figures (`tnum`) to ensure perfect vertical column alignment.
- Overline labels (e.g., column headers, status markers, inventory classification tags) utilize `label-sm` with slight positive tracking (`+0.04em`) and uppercase transformation.
- Critical text contrast ratios strictly respect WCAG AA (4.5:1 minimum against slate backgrounds).

## Layout & Spacing

A 12-column responsive layout engine optimized for dual modes: analytical dashboard summaries and multi-row inventory registers.

### Breakpoints & Adaptations
- **Mobile (< 768px):** 4-column layout, margin `1rem`, gutter `1rem`. Tables collapse into structured inventory summary cards with collapsible drawer sheets for batch actions.
- **Tablet (768px - 1199px):** 8-column layout, margin `1.5rem`, gutter `1rem`. Persistent condensed icon rail navigation with horizontal scrollable tables for secondary columns.
- **Desktop (≥ 1200px):** 12-column fluid grid, margin `2rem`, gutter `1.5rem`. Fixed left sidebar (240px wide), permanent filter bars, split-screen master-detail views for departmental requisitions.

### Density Rhythm
Components and table rows adhere to an 8px grid baseline:
- Compact data rows measure 36px in height for dense SKU lists.
- Standard inspection rows measure 44px with comfortable click targets.
- Card padding defaults to `space-md` (`14px`) internally and `space-lg` (`20px`) for root analytics containers.

## Elevation & Depth

Visual hierarchy uses a refined hybrid of **low-contrast borders** and **ambient slate-tinted shadows**. Heavy drop shadows are omitted to maintain a modern, surgical industrial feel.

### Depth Hierarchy
- **Level 0 (Canvas):** `#F8FAFC` flat surface.
- **Level 1 (Cards, Modules, Table Containers):** `#FFFFFF` with a 1px border in `#E2E8F0` and shadow `0 1px 3px 0 rgba(15, 23, 42, 0.05)`.
- **Level 2 (Hover States, Popovers, Filter Menus):** `#FFFFFF` with 1px border in `#CBD5E1` and shadow `0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.04)`.
- **Level 3 (Modals, Slide-over Drawers, Batch Actions Rail):** `#FFFFFF` with shadow `0 20px 25px -5px rgba(15, 23, 42, 0.12), 0 8px 10px -6px rgba(15, 23, 42, 0.06)`.
- **Overlays:** Dark slate backdrop blur `rgba(15, 23, 42, 0.45)` with `backdrop-filter: blur(4px)`.

## Shapes

The design system employs a **Soft (`1`)** shape language (`4px` base border radius, `8px` for cards and inputs, `12px` for dialogs). This tight geometry reinforces stability, industrial order, and structure, avoiding excessive playfulness while preserving soft, approachable touchpoints.

### Corner Radius Mapping
- **Buttons, Text Inputs, Selects, Dropdowns:** `0.375rem` (6px)
- **Data Table Containers & Analytics Cards:** `0.5rem` (8px)
- **Modal Windows & Detail Drawers:** `0.75rem` (12px)
- **Pill Badges & Indicator Tags:** `9999px` (Full Pill) for immediate status distinction

## Components

### Buttons
- **Primary:** Background `#48B8C5`, text `#FFFFFF`, font `label-lg`, height `38px`, padding `0 16px`. Hover state darkens to `#389FA9`. Focus state applies a 2px offset ring in `#48B8C5`.
- **Secondary (Corporate Action):** Background `#0F172A`, text `#FFFFFF`. Hover state `#1E293B`.
- **Outline / Ghost:** Border 1px `#E2E8F0`, background transparent, text `#0F172A`. Hover background `#F1F5F9`.
- **Destructive:** Background `#EF4444`, text `#FFFFFF`. Hover `#DC2626`.

### Badges & Status Chips (Pill Shaped)
High-scannability status markers using a subtle background tint + high-contrast text:
- **In Stock / Valid (>30d):** Background `#ECFDF5`, text `#065F46`, dot indicator `#10B981`.
- **Warning (30 Days):** Background `#FEF3C7`, text `#92400E`, dot indicator `#F59E0B`.
- **Alert (15 Days):** Background `#FFEDD5`, text `#9A3412`, dot indicator `#F97316`.
- **Critical (5 Days):** Background `#FFEDD5`, text `#C2410C`, dot indicator `#EA580C`.
- **Expired / Out of Stock:** Background `#FEE2E2`, text `#991B1B`, dot indicator `#EF4444`.

### Tables (High-Density Data Grid)
- **Header:** Background `#F8FAFC`, bottom border 1px `#E2E8F0`, text `label-sm` in uppercase Slate 500 (`#64748B`).
- **Rows:** Alternating subtle hover `#F8FAFC`, bottom border 1px `#F1F5F9`. Cell padding `10px 16px`.
- **Numbers & Dates:** Right-aligned with tabular figures font setting.

### Input Fields & Controls
- **Inputs:** Height `38px`, border 1px `#CBD5E1`, background `#FFFFFF`, text `body-md` in `#0F172A`. Focus state replaces border with `#48B8C5` and provides a 2px glow ring with 20% opacity.
- **Checkboxes & Radios:** Size `16px`, border `#94A3B8`, active fill `#48B8C5` with white checkmark glyph.

### Cards & Metrics (KPI Widgets)
- White surface, 1px border `#E2E8F0`, subtle shadow. Top or accent edge can include a 3px colored stripe representing status (e.g., cyan primary for Total Items, amber for Expiring Soon).