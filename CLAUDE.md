# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

HeyMarketers is a marketplace connecting businesses with marketing professionals. Built with:
- **Ruby on Rails 7.1** with PostgreSQL database
- **Devise** for authentication with confirmable and trackable modules
- **Tailwind CSS + DaisyUI** with custom "ice" theme
- **Hotwire** (Turbo + Stimulus) for frontend interactivity
- **ViewComponent** for reusable UI components
- **pg_search** for full-text search capabilities
- **Flexible account architecture** allowing users to be both marketers and employers

## Development Commands

### Setup
```bash
bin/setup                    # Initial setup - installs dependencies and prepares database
bundle install               # Install Ruby gems
yarn install                 # Install Node.js dependencies (Tailwind CSS + DaisyUI)
bin/rails db:prepare         # Setup database
bin/rails db:seed            # Seed database with skills, locations, service types
```

### Running the Application
```bash
bin/dev                      # Start development server with Foreman (web + CSS watching)
bin/rails server             # Start web server only
yarn build:css               # Build CSS with Tailwind + DaisyUI + custom ice theme
yarn build:css --watch       # Watch and rebuild CSS on changes
```

### Database Operations
```bash
bin/rails db:migrate         # Run pending migrations
bin/rails db:rollback        # Rollback last migration
bin/rails db:seed            # Run seed data
bin/rails db:reset           # Drop, create, migrate, and seed database
```

### Testing
```bash
bin/rails test              # Run all tests
bin/rails test test/models  # Run model tests
bin/rails test:system       # Run system tests with Capybara/Selenium
```

### Rails Utilities
```bash
bin/rails console           # Interactive Rails console
bin/rails routes            # Show all routes
bin/rails generate          # Code generation
```

## Architecture

### Application Structure
- **Module Name**: `Heymarketers` (defined in config/application.rb:21)
- **Ruby Version**: 3.2.2
- **Rails Version**: 7.1.3+

### Key Components
- **Controllers**: Standard Rails controllers in `app/controllers/`
- **Models**: ActiveRecord models in `app/models/`
- **Views**: ERB templates in `app/views/` with Tailwind CSS styling
- **Frontend**: Hotwire (Turbo + Stimulus) with import maps
- **Testing**: Rails default test framework with parallel execution enabled
- **Database**: PostgreSQL with Active Record

### Configuration
- **Routes**: Currently minimal setup in `config/routes.rb` with health check endpoint
- **Application Config**: Standard Rails 7.1 configuration in `config/application.rb`
- **Development**: Uses Foreman via `bin/dev` to run web server and CSS watcher concurrently

### Frontend Stack
- **CSS Framework**: Tailwind CSS with live recompilation in development
- **JavaScript**: Import maps for ES6 modules
- **Interactivity**: Hotwire (Turbo for SPA-like navigation, Stimulus for JavaScript components)

## Design System

### Custom Theme
The application uses a custom green-based design system with comprehensive theming support:

#### Color Palette
- **Primary**: `#457f3d` (Forest Green) - Used for buttons, links, and primary actions
- **Secondary**: `#f5f5f4` (Light Gray) - Used for secondary elements
- **Background**: `#fafaf9` (Warm White) - Main background color
- **Foreground**: `#402a2b` (Dark Brown) - Primary text color
- **Accent**: `#e9f2e7` (Light Green) - Highlights and accents
- **Muted**: `#72514e` (Muted Brown) - Secondary text

#### Typography
- **Primary Font**: Montserrat (sans-serif) - Modern, clean typeface
- **Serif Font**: Merriweather (serif) - For emphasis and headings
- **Mono Font**: Source Code Pro (monospace) - For code and technical content

#### Component Classes
Use these standardized CSS classes for consistent styling across the application:

**Buttons:**
- `.btn` - Base button styles
- `.btn-primary` - Primary green button
- `.btn-secondary` - Secondary light button
- `.btn-outline` - Outlined button
- `.btn-ghost` - Transparent button
- `.btn-sm`, `.btn-lg` - Size variants

**Cards:**
- `.card` - Card container with proper shadows and borders
- `.card-body` - Standard card content padding

**Badges:**
- `.badge` - Base badge styles
- `.badge-primary`, `.badge-secondary`, `.badge-accent` - Color variants
- `.badge-outline` - Outlined badge

**Form Elements:**
- `.input` - Styled form inputs with proper focus states

**Layout:**
- Use CSS custom properties for colors: `var(--color-primary)`, `var(--color-foreground)`, etc.
- Dark mode support available via `.dark` class
- Consistent border radius: `var(--radius)`
- Standardized shadows: `var(--shadow-sm)`, `var(--shadow-md)`, etc.

#### Development Guidelines
1. **Always use design system classes** instead of custom Tailwind utilities for colors
2. **Reference CSS variables** for consistency: `style="color: var(--color-primary);"`
3. **Font loading** handled via Google Fonts in layout
4. **Theme compilation** via `yarn build:css` command
5. **Future components** should follow existing patterns in `app/assets/stylesheets/application.tailwind.css`

This is a mature Rails application with a comprehensive design system, following standard Rails conventions and modern Rails 7 patterns.