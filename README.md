# Kendra — Enterprise Business Operating System

This package is the deployment-ready static version of the supplied Kendra HTML app.

## What was changed

- Replaced the local Windows-only font stylesheet reference with the equivalent Google Fonts stylesheet.
- Connected authentication to Supabase Auth while preserving the existing login/sign-up/forgot-password UI.
- Added automatic Supabase workspace creation/linking through `businesses` and `profiles`.
- Added database hydration for the existing Employees, Customers, Products, Suppliers, Goods Movements, Invoices, Expenses, Tasks, and Documents datasets.
- Added background synchronization from the existing browser-local data layer to Supabase so the existing UI and feature functions continue to operate unchanged.
- Added optional `kendra_meta` JSONB columns so dynamic/imported fields not present in the fixed schema can remain persistent across devices.
- Kept the current HTML/CSS layout, KPI cards, Business Health UI, charts, navigation, modals, and feature behavior intact.

## Supabase setup

1. Open the Supabase SQL Editor for the project configured in `index.html`.
2. Run `supabase-schema (1).sql`.
3. Run `supabase-migration.sql`.
4. In Supabase Authentication, configure the email confirmation/reset-link settings for your deployment URL as required by your project.

The frontend uses the project's public `anon` key. Database access is protected by the RLS policies in the supplied schema.

## Vercel deployment

1. Put `index.html` at the repository root.
2. Create/import the GitHub repository in Vercel.
3. Use the default static deployment settings; no build command is required.
4. Deploy.

The application is intentionally kept as a single HTML file so the existing UI and client-side architecture are not reworked.

## Important behavior

The browser cache remains in place as a local fallback, but authenticated workspaces load their current records from Supabase and changes are synchronized back to the same business workspace. This preserves the existing frontend behavior while adding cross-session persistence.
