# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

mini-painter is a Rails/React application for uploading and browsing collections of painted miniatures. It's hosted at [mini-painter.com](https://mini-painter.com).

## Development Setup

### Rails Backend

Install Ruby dependencies:
```bash
bundle install
```

Run database migrations:
```bash
rake db:migrate
```

Start the Rails server:
```bash
rails s
```

### React Frontend

Install client dependencies:
```bash
yarn install
```

Build JavaScript files and watch for changes:
```bash
yarn build --watch
```

Build CSS and watch for changes:
```bash
yarn build:css --watch
```

**Important:** The FontAwesome token must be exported in your shell environment before running `yarn build`. Adding it to `.env` is not sufficient:
```bash
export FONTAWESOME_PACKAGE_TOKEN="YOUR_TOKEN_HERE"
```

### Running Tests

Standard Rails test commands:
```bash
# Run all tests
rake test

# Run specific test file
rake test test/models/user_test.rb

# Run system tests
rake test:system
```

## Architecture Overview

### Hybrid Rails/React Architecture

This application uses a hybrid approach where Rails serves pages with embedded React components. **This is not a SPA** - React components are mounted into Rails-rendered views.

**Component Mounting System:**
- `app/components/react_component.rb` - Rails ViewComponent that creates mount points for React components
- `app/javascript/mount.tsx` - Client-side function that finds `[data-react-component]` elements and mounts React components
- `app/javascript/application.tsx` - Registry of all available React components

**How it works:**
1. Rails controller renders a view with `ReactComponent.new("ComponentName", raw_props: {...})`
2. This creates a div with `data-react-component="ComponentName"` and `data-props="{...}"`
3. On page load, `mount()` finds these divs and renders the corresponding React component with the props

### Frontend Structure

React components are organized by feature:
- `app/javascript/auth/` - Authentication forms (sign in, sign up, password reset)
- `app/javascript/Collection/` - User's personal collection management
- `app/javascript/CollectionFaction/` - Faction detail view with groups, models, and gallery
- `app/javascript/CollectionUserModel/` - Individual model detail view
- `app/javascript/Explore/` - Browse game systems, factions, and models catalog
- `app/javascript/Social/` - Social feed, posts, comments, reactions
- `app/javascript/TopNavBar/` - Navigation component
- `app/javascript/common/` - Shared components
- `app/javascript/types/` - TypeScript type definitions
- `app/javascript/utils/` - Utility functions

Build process uses esbuild (configured in package.json scripts) and outputs to `app/assets/builds/`.

### Backend Structure

**Models:**
- `User` - User accounts with encrypted passwords, profile pictures, bio
- `GameSystem` - Top-level game systems (e.g., Warhammer 40k)
- `Faction` - Factions within game systems (e.g., Space Marines)
- `Model` - Available models within factions (catalog data)
- `UserFaction` - User's collection of a specific faction
- `UserModel` - User's instance of a model with quantities by status (unassembled/assembled/in_progress/finished)
- `UserModelGroup` - Groups within user factions for organization
- `UserImage` - Images stored in S3
- `UserImageAssociation` - Polymorphic joins for images to factions/models/posts
- `Post` - Social feed posts
- `PostComment` - Comments on posts
- `PostReaction` - Reactions (emoji) on posts and comments
- `UserFollow` - User following relationships

**Controllers:**
- `AuthController` - Authentication flows
- `CollectionController` - CRUD for user's collection (factions, models, groups, images)
- `MyProfileController` - User profile updates
- `SocialController` - Posts, comments, reactions, follows, user browsing
- `ExploreController` - Browse catalog of game systems, factions, models
- `GameSystemsController` - Create game systems
- `FactionsController` - Create/update factions and models
- `UserAssetsController` - S3 upload URLs

**Key Architectural Patterns:**
- Password encryption uses `attr_encrypted` gem with Rails encryption key
- Image storage uses AWS S3 via `S3Client` service (`app/services/s3_client.rb`)
- Background jobs use `delayed_job_active_record`
- Database: PostgreSQL
- User models track quantities by status: `qty_unassembled`, `qty_assembled`, `qty_in_progress`, `qty_finished`
- Images are associated polymorphically via `UserImageAssociation` (can belong to user_faction, user_model, or post)

### Routes Structure

The app has several main sections (see `config/routes.rb`):
- `/sign-in`, `/sign-up`, `/forgot-password`, `/password-reset` - Authentication
- `/my-profile` - User profile management
- `/my-collection` - User's collection of factions and models
- `/social` - Social feed and user browsing
- `/models`, `/game-systems/:id`, `/factions/:id` - Catalog exploration
- `/api/users/:user_id/*` - JSON APIs for fetching user data

## Common Development Patterns

### Adding a New React Component

1. Create the component in `app/javascript/ComponentName/`
2. Import and register it in `app/javascript/application.tsx`
3. Use it from Rails: `render ReactComponent.new("ComponentName", raw_props: { ... })`

### Working with TypeScript

TypeScript is configured with strict mode. Type definitions for models are in `app/javascript/types/models.ts`. When adding new model fields, update the TypeScript types.

### Database Migrations

Follow standard Rails migration practices:
```bash
rails generate migration MigrationName
# Edit the migration file
rake db:migrate
```

### Image Upload Flow

1. Frontend requests presigned S3 URL from `/user-assets/upload`
2. Upload directly to S3 using presigned URL
3. Create `UserImage` record with S3 URL
4. Create `UserImageAssociation` to link image to faction/model/post
