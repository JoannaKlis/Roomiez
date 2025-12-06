# 🏢 Roomies

Manage your place. Together. 

**Roomies** is an innovative tool that will allow you and your roomates to manage:
- expenses
- chores
- communication

... in one place!

---

## 🚀 Key System Capabilities

### 💰 Financial Module (Expenses & Settlements)
* **Transaction Ledger:** Add shared expenses in real-time.
* **Settlement Algorithm:** Automatically calculates balances for each user ("who owes whom").
* **Operation History:** Full expense audit to prevent ambiguities.

### 📅 Organizational Module (Tasks & Schedule)
* **Task Delegation:** Assign chores to specific people with deadlines.
* **Status Tracking:** Monitor progress (To Do / Done).
* **Smart Shopping List:** A shared database of needed products, updated live by all housemates.

### 📢 Communication Hub (Announcements)
* **Notice Board:** A channel for conveying critical information (e.g., breakdowns, landlord visits, events). Guarantees that information reaches all group members.

### 🔐 Security & Administration
* **Role-Based Access Control (RBAC):**
    * **Admin:** Manage group composition, remove members, view full statistics.
    * **Member:** Full access to utility functions (tasks, expenses).
* **Authentication:** Secure login and registration based on **Firebase Auth**.
* **Cloud Data:** All data is synchronized in real-time thanks to **Firestore**.

---
## 💎 Our Value

The project addresses real needs in the rental and student housing market, offering:

### 1. Financial Transparency (FinTech)
Solves the "who paid for what" problem. The expense tracking and automatic settlement system ensures full transparency of cash flows within the group, significantly reducing economic conflicts.

### 2. Micro-Community Management
Thanks to the role system (**Admin vs Member**), the application scales from small student apartments to managed units in dormitories. The Administrator (e.g., property manager or "head tenant") has control tools (`Admin Dashboard`), allowing for effective management of the resident structure.

### 3. Operational Efficiency (Task Management)

Replaces analog charts and fridge notes with a digital task delegation system (`Tasks`) and resource management (`Shopping List`). This increases user accountability and streamlines the daily functioning of the household.

---
## 🛠 Tech Stack

The project utilizes a modern technology stack ensuring performance, scalability, and maintainability (Single Codebase):

* **Frontend:** [Flutter](https://flutter.dev/) (Dart) – Native performance on Android, iOS, and Web.
* **Backend as a Service:** [Firebase](https://firebase.google.com/)
    * **Authentication:** Identity management.
    * **Cloud Firestore:** Scalable NoSQL database working in real-time.
* **Architecture:** Modular code structure facilitating further development and adding new features (e.g., in-app payments).

---

## 📂 Project Structure

The project is designed with easy expansion in mind:

```text
lib/
├── models/         # Data models (scalable JSON structures)
├── screens/        # User Interface (UI/UX)
│   ├── admin_...   # Management panels (Admin Dashboard)
│   ├── expenses... # Financial logic
│   └── ...
├── services/       # Communication layer with API/Firebase
└── widgets/        # Reusable interface components (Design System)
```

## 🚀 How to run the app?

### Requirements
* **Flutter SDK** (Latest Stable).
* **Firebase CLI** (to manage cloud connection).

### Instructions

1. **Repo download:**
   ```bash
   git clone [https://github.com/twoj-login/roomiez.git](https://github.com/twoj-login/roomiez.git)
   cd roomiez

2. **Dependencies installation:**
   ```bash
    flutter pub get

3. **Firebase env configuration:**
   ```bash
    flutterfire configure

4. **Build**
   ```bash
    flutter run


## Screens yayyyy
