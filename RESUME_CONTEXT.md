# SunState Classifieds - Implementation Resume Context

**Last Updated:** 2026-05-29 15:20 UTC
**Status:** In Progress - Phase 1 Foundation

---

## Project Overview

Building a Florida-focused classifieds marketplace similar to KSL Classifieds (Utah), branded as **SunState Classifieds**.

### Key Decisions Made

| Decision | Choice |
|----------|--------|
| Brand | SunState Classifieds |
| Transactions | Contact-only (no payment processing) |
| Hosting | Fly.io (portable to AWS later) |
| Database | PostgreSQL |
| Location | Single site with zip/city + radius filters |
| Verification | Email + Stripe Identity for "Verified Seller" badge |
| Listing Types (MVP) | For Sale only |
| Categories (MVP) | 10-15 core categories |
| Access Model | Browse publicly, login to contact/favorite/post |

### Tech Stack

- Phoenix 1.8.7 with LiveView
- PostgreSQL with citext extension
- Tailwind CSS v4 + daisyUI
- Bcrypt for password hashing
- NimbleTOTP for 2FA
- Stripe Identity for seller verification
- ExAWS/ExAWS.S3 for image storage
- Cachex for rate limiting

---

## Current Progress

### Completed Tasks

1. **Project Renamed** - Changed from `project` to `sunstate`
   - All module names, configs, database names updated
   - All files in `lib/sunstate/` and `lib/sunstate_web/`

2. **Dependencies Added** to mix.exs:
   - bcrypt_elixir, nimble_totp, image, ex_aws, ex_aws_s3
   - eqrcode, nimble_csv, cachex, stripity_stripe

3. **Users Migration & Schema Created**
   - Migration: `priv/repo/migrations/20260529185306_create_users.exs`
   - Schema: `lib/sunstate/accounts/user.ex`
   - Fields: email, hashed_password, display_name, phone, phone_verified, avatar_url
   - Email verification: confirmed_at
   - 2FA: totp_secret, totp_enabled, backup_codes
   - Stripe Identity: stripe_identity_session_id, stripe_identity_status, identity_verified_at
   - Settings: contact_preferences, notification_settings
   - Soft delete: deactivated_at
   - **Migration has been run successfully**

4. **User Tokens Migration & Schema Created**
   - Migration: `priv/repo/migrations/20260529191827_create_user_tokens.exs`
   - Schema: `lib/sunstate/accounts/user_token.ex`
   - For session tokens, email confirmation, password reset
   - **Migration has been run successfully**

5. **Categories Migration Generated** (empty, needs content)
   - Migration: `priv/repo/migrations/20260529192030_create_categories.exs`

### In Progress

**Creating remaining migrations and schemas:**

---

## NEXT STEPS TO RESUME

### Immediate Next Command

```bash
mix ecto.gen.migration create_listings
```

Then continue generating:
```bash
mix ecto.gen.migration create_listing_images
mix ecto.gen.migration create_favorites
mix ecto.gen.migration create_zip_codes
```

### Remaining Tasks (in order)

1. **Fill in Categories migration** (`priv/repo/migrations/20260529192030_create_categories.exs`)
   - Fields: name, slug, icon, position, parent_id (for subcategories)
   - Create Category schema at `lib/sunstate/listings/category.ex`

2. **Create Listings migration and schema**
   - Generate migration file (command above)
   - Fields: title, description, price, price_type, condition, status
   - Location: zip_code, city, state, latitude, longitude
   - Search: search_vector (PostgreSQL generated column for full-text search)
   - Metrics: view_count, favorite_count
   - Dates: expires_at, featured_until
   - Create schema at `lib/sunstate/listings/listing.ex`

3. **Create Listing Images migration and schema**
   - Fields: storage_key, variants (thumbnail/medium/large paths), position, is_primary
   - Create schema at `lib/sunstate/listings/listing_image.ex`

4. **Create Favorites migration and schema**
   - Fields: user_id, listing_id (unique index)
   - Create schema at `lib/sunstate/listings/favorite.ex`

5. **Create Zip Codes migration and schema**
   - Fields: zip (primary key), city, county, latitude, longitude
   - Create schema at `lib/sunstate/locations/zip_code.ex`
   - Will seed with Florida zip code data later

6. **Build Accounts context** (`lib/sunstate/accounts/accounts.ex`)
   - Registration, login, email confirmation, password reset
   - Session token management
   - 2FA setup/verification

7. **Create Auth LiveViews**
   - `lib/sunstate_web/live/user_registration_live.ex`
   - `lib/sunstate_web/live/user_login_live.ex`
   - `lib/sunstate_web/live/user_settings_live.ex`

8. **Set up routes and auth plugs**
   - Update `lib/sunstate_web/router.ex`
   - Create auth plugs for `require_authenticated_user`, `fetch_current_user`

---

## File Structure Reference

```
lib/
├── sunstate/
│   ├── accounts/
│   │   ├── user.ex           # DONE
│   │   ├── user_token.ex     # DONE
│   │   └── accounts.ex       # TODO - main context
│   ├── listings/
│   │   ├── listing.ex        # TODO
│   │   ├── category.ex       # TODO
│   │   ├── listing_image.ex  # TODO
│   │   ├── favorite.ex       # TODO
│   │   └── listings.ex       # TODO - main context
│   ├── locations/
│   │   ├── zip_code.ex       # TODO
│   │   └── locations.ex      # TODO - main context
│   ├── application.ex
│   ├── mailer.ex
│   └── repo.ex
├── sunstate_web/
│   ├── live/
│   │   ├── user_registration_live.ex  # TODO
│   │   ├── user_login_live.ex         # TODO
│   │   └── user_settings_live.ex      # TODO
│   ├── router.ex             # Needs auth routes
│   └── ...
priv/
└── repo/
    └── migrations/
        ├── 20260529185306_create_users.exs         # DONE & MIGRATED
        ├── 20260529191827_create_user_tokens.exs   # DONE & MIGRATED
        ├── 20260529192030_create_categories.exs    # GENERATED, NEEDS CONTENT
        ├── [timestamp]_create_listings.exs         # TODO - GENERATE NEXT
        ├── [timestamp]_create_listing_images.exs   # TODO
        ├── [timestamp]_create_favorites.exs        # TODO
        └── [timestamp]_create_zip_codes.exs        # TODO
```

---

## Full Plan Reference

The complete implementation plan is at: `/Users/robert/.claude/plans/fluffy-honking-kite.md`

This covers all 6 phases:
1. Foundation (MVP Core) - **CURRENTLY IN PROGRESS**
2. Listings & Search
3. Image Storage & Processing
4. Contact & Messaging
5. Security & Verification
6. Polish & Production

Plus future phases 7-11 for post-MVP features.

---

## Database State

- Database name: `sunstate_dev` (dev), `sunstate_test` (test)
- citext extension installed
- Tables created: `users`, `user_tokens`
- Tables pending: `categories`, `listings`, `listing_images`, `favorites`, `zip_codes`

To verify current state:
```bash
mix ecto.migrations  # Shows migration status
mix test             # Should pass (5 tests)
```

---

## Resume Instructions

1. Open this project in Claude Code
2. Tell Claude: "Resume the SunState Classifieds implementation. Read RESUME_CONTEXT.md for current state."
3. The next command to run is: `mix ecto.gen.migration create_listings`
4. Then continue with the remaining migrations and schemas as listed above
