# DMS — Setup & Deploy

Multi-user, login-gated Defect Management System.
**Stack (free):** GitHub Pages (hosting) + Supabase (Postgres + Storage + Auth).

The app runs in two modes automatically:
- **Offline/demo** — while `project/config.js` still has the placeholder keys:
  localStorage only, no login, single-device. (Good for a quick local look.)
- **Cloud** — once real Supabase keys are in `config.js`: login required, shared
  data across all users/devices.

---

## 1. Create the Supabase backend (free, ~5 min)

1. Sign up at https://supabase.com and create a new project (remember the DB password).
2. Open **SQL Editor → New query**, paste all of [`supabase/schema.sql`](supabase/schema.sql),
   and **Run**. This creates the `defects` + `app_config` tables, the
   `defect-photos` storage bucket, and the login-only security policies.
3. Create your team logins: **Authentication → Users → Add user** (email + password)
   for each person. (Or **Authentication → Providers → Email** to allow self sign-up.)
4. **Project Settings → API** — copy:
   - **Project URL**
   - **Project API keys → `anon` `public`**

## 2. Add your keys

Edit **`project/config.js`** and replace the two placeholder lines with the values
from step 4. The `anon` key is safe to commit — security is enforced server-side by
the SQL policies. (Never paste the `service_role` key.)

The first time anyone logs in, the app auto-seeds the shared database with the
bundled hotels/rooms config and the 132 imported defects (idempotent — runs once).

## 3. Deploy to GitHub Pages

The repo's **`docs/`** folder is the deployed copy of the app (the same runtime
files as `project/`).

1. In the repo: **Settings → Pages → Build and deployment → Source: Deploy from a
   branch → Branch: `main` / folder: `/docs` → Save.**
2. Wait ~1 minute; the live URL appears at the top of the Pages settings, e.g.
   `https://purang19.github.io/Defect-Management/`.

Open that URL → login screen → sign in → defects load. Open it on a second
device/account to confirm shared, real-time data.

> To update Supabase keys for the live site, edit **`docs/config.js`**.
> If you change the app, copy the runtime files from `project/` into `docs/`.

---

## Notes
- Free Supabase storage = 1 GB (~6,000 compressed photos); pauses after ~7 days of
  inactivity (one click in the dashboard to wake).
- New photos upload to the `defect-photos` bucket; the 132 imported records keep
  their original image URLs.
- To change hotels/buildings/rooms or the dropdown catalogs, just edit them in the
  app — changes sync to `app_config` for everyone.
