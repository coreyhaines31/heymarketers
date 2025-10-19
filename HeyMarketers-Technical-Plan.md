# HeyMarketers — Technical & Product Plan

A directory marketplace for finding and hiring marketers.  
Built with **Ruby on Rails**, **Hotwire**, and **Tailwind CSS + DaisyUI**.

> Note: You have a custom DaisyUI theme ready to import. This plan assumes it’s not installed yet and will be added when the UI foundation is in place.

---

## 🧱 Tech Stack

### **Core**
- **Ruby on Rails 8** (or 7.2 for stability)
- **PostgreSQL** for primary database
- **Turbo + Stimulus** for reactive UI (no SPA complexity)
- **Tailwind CSS** via `cssbundling-rails`
- **DaisyUI** for pre-built, themeable Tailwind components *(theme to be imported when ready)*
- **ViewComponent** for modular, reusable UI elements

### **Authentication**
- **Devise** for user authentication
  - Single `User` model for all users (marketers, employers, or both)
  - Flexible roles via `Membership` on `Account`
  - Include modules: `confirmable`, `recoverable`, `trackable`, `omniauthable` (optional)

### **Storage & Uploads**
- **ActiveStorage** → **Cloudflare R2** or **AWS S3**
  - For profile photos, resumes, company logos, etc.

### **Search**
- **pg_search** for full-text and faceted search
- Optional: **Meilisearch** for faster, fuzzy, multi-field search

### **Background Jobs**
- **Solid Queue** (Rails 8 default)
- Optional: **GoodJob** (PostgreSQL-backed async jobs)

### **Email & Notifications**
- **Action Mailer** with **Postmark** or **Resend**
- **Turbo Streams** for in-app live notifications

### **Admin**
- **Avo** or **Administrate** for lightweight admin panel

---

## 🧩 Core Domain Models

| Model | Description |
|-------|--------------|
| **User** | Authenticated user account via Devise. Can act as both marketer and employer. |
| **Account** | Logical entity representing an organization or individual profile. |
| **Membership** | Join table between `User` and `Account`, defining roles. |
| **MarketerProfile** | Belongs to an account. Holds bio, skills, rate, and location. |
| **CompanyProfile** | Belongs to an account. Stores employer data and job listings. |
| **Skill** | Tag model for marketer categorization. |
| **Location** | Stores geographic regions for search and SEO. |
| **ServiceType** | Defines engagement type (full-time, contract, hourly, etc.). |
| **Job** | Job listings posted by companies. |
| **Application** | Connects marketers with jobs they apply to. |
| **Message** | Chat messages between marketers and companies. |
| **ContactRequest** | Inquiry form for managed service or contact leads. |
| **Admin** | Internal user managing sourcing and vetting. |

---

## 🧠 Flexible Account Architecture

A unified user-account relationship allows total flexibility.  
Any user can act as both a marketer and an employer.

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable, :trackable

  has_many :memberships
  has_many :accounts, through: :memberships

  def marketer?
    accounts.joins(:marketer_profile).exists?
  end

  def employer?
    accounts.joins(:company_profile).exists?
  end
end

class Account < ApplicationRecord
  has_many :memberships
  has_many :users, through: :memberships

  has_one :marketer_profile, dependent: :destroy
  has_one :company_profile, dependent: :destroy
end

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :account
  enum role: { owner: 0, member: 1 }
end
```

This structure allows:
- One unified user base.
- Multi-account and multi-role flexibility.
- Future-proofing for teams, agencies, and organizations.

---

## 🗂️ Core Features

### **1. Marketer Profiles**
- Name, title, bio, hourly rate
- Skills, location, availability
- Portfolio links and resume uploads
- Friendly URLs: `/marketers/jordan-chand`

### **2. Directory Search**
- Filter by skills, location, service type, rate
- Full-text + faceted search
- Paginated results
- Programmatic SEO pages:
  - `/marketers/seo`
  - `/marketers/california`
  - `/marketers/contract`
  - `/marketers/seo/california/contract`

### **3. Company Profiles**
- Company name, logo, description
- Team members (linked via Membership)
- Job listings

### **4. Jobs**
- CRUD job listings
- Job-to-skill associations
- Public job directory: `/jobs`

### **5. Messaging**
- Direct messaging between marketers and employers
- Real-time updates via Turbo Streams
- Email alerts for unread messages

### **6. Managed Hiring Service**
- Intake form: “Find a marketer for me”
- Admin workflow for vetting, shortlisting, and tracking candidate status
- Internal notes and stage tracking

---

## 🧭 Programmatic SEO Plan

Dynamic page generation from combinations of filters:

```
/marketers/:skill
/marketers/:location
/marketers/:service_type
/marketers/:skill/:location
/marketers/:skill/:location/:service_type
```

Each combination:
- Queries the `MarketerProfile` index
- Populates SEO metadata dynamically
- Uses fragment caching for speed
- Optionally pre-generates top combinations

---

## 💬 Example Use Cases

| Persona | Flow |
|----------|------|
| **Freelance Marketer** | Creates account → builds profile → receives inbound leads or applies to jobs |
| **Startup Founder** | Signs up → creates company → posts job → browses directory → messages candidates |
| **Recruiter / Agency** | Uses managed service intake → receives shortlists of vetted marketers |

---

## 🧩 Database Schema Diagram

```text
┌────────────────────┐
│       users         │
├────────────────────┤
│ id: bigint          │
│ email: string       │
│ encrypted_password  │
│ confirmed_at        │
│ role: string?       │
│ timestamps          │
└────────────────────┘
           │
           │ has_many
           ▼
┌────────────────────┐
│     memberships     │
├────────────────────┤
│ id: bigint          │
│ user_id: bigint     │
│ account_id: bigint  │
│ role: integer       │
│ timestamps          │
└────────────────────┘
           │
           │ belongs_to
           ▼
┌────────────────────┐
│      accounts       │
├────────────────────┤
│ id: bigint          │
│ name: string        │
│ slug: string        │
│ timestamps          │
└────────────────────┘
      │             │
      │             │
      ▼             ▼
┌────────────────────┐     ┌────────────────────┐
│ marketer_profiles   │     │  company_profiles  │
├────────────────────┤     ├────────────────────┤
│ id: bigint          │     │ id: bigint         │
│ account_id: bigint  │     │ account_id: bigint │
│ title: string       │     │ name: string       │
│ bio: text           │     │ description: text  │
│ hourly_rate: int    │     │ logo: ActiveStorage│
│ location_id: bigint │     │ location_id: bigint│
│ timestamps          │     │ timestamps         │
└────────────────────┘     └────────────────────┘
      │
      │ many-to-many (via join)
      ▼
┌────────────────────┐
│      skills         │
├────────────────────┤
│ id: bigint          │
│ name: string        │
│ slug: string        │
└────────────────────┘
      │
      ▼
┌────────────────────┐
│  marketer_skills    │ (join table)
├────────────────────┤
│ marketer_profile_id │
│ skill_id            │
└────────────────────┘

┌────────────────────┐
│      locations      │
├────────────────────┤
│ id: bigint          │
│ name: string        │
│ slug: string        │
└────────────────────┘

┌────────────────────┐
│    service_types    │
├────────────────────┤
│ id: bigint          │
│ name: string        │
│ slug: string        │
└────────────────────┘

┌────────────────────┐
│        jobs         │
├────────────────────┤
│ id: bigint          │
│ company_profile_id  │
│ title: string       │
│ description: text   │
│ service_type_id     │
│ location_id         │
│ rate: integer?      │
│ timestamps          │
└────────────────────┘
      │
      ▼
┌────────────────────┐
│    applications     │
├────────────────────┤
│ id: bigint          │
│ job_id: bigint      │
│ marketer_profile_id │
│ status: string      │
│ message: text       │
│ timestamps          │
└────────────────────┘

┌────────────────────┐
│      messages       │
├────────────────────┤
│ id: bigint          │
│ sender_id: bigint   │ (User)
│ receiver_id: bigint │ (User)
│ body: text          │
│ read_at: datetime?  │
│ timestamps          │
└────────────────────┘

┌────────────────────┐
│   contact_requests  │
├────────────────────┤
│ id: bigint          │
│ name: string        │
│ email: string       │
│ message: text       │
│ handled_by_admin_id │
│ status: string      │
│ timestamps          │
└────────────────────┘
```

---

## 🚀 Development Roadmap

### **Phase 1: MVP**
- Devise auth + unified user/account setup
- CRUD for marketer profiles
- Directory search + filters
- Contact form (DM or lead form)
- Basic programmatic SEO pages

### **Phase 2: Employers + Jobs**
- Company profiles
- Job listings + applications
- Notifications via email and Turbo

### **Phase 3: Managed Service**
- Intake form for sourcing requests
- Admin workflow for vetting marketers

### **Phase 4: Monetization**
- Stripe Connect for marketplace payments
- Featured listings / visibility boosts
- Subscription tiers (for marketers)

---

## 🧠 Future Enhancements
- Reviews & testimonials
- Saved favorites / shortlists
- AI-powered matching via `pgvector`
- Public API
- Team / agency accounts

---

## 🧩 UI & Design Guidelines
- **Tailwind + DaisyUI** components for all UI
- **Custom DaisyUI theme will be imported when ready**
- Keep consistent spacing, rounded corners, and minimal color palette
- Layouts:
  - `application.html.erb` → header, flash, yield
  - Use ViewComponents for cards, forms, and filter UIs
- Theme: **modern SaaS aesthetic** (neutral tones, crisp typography)
