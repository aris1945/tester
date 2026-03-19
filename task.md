# Flutter Admin Dashboard & Assign Technician Modal Implementation

## 1. Match Admin Dashboard UI exactly to Next.js

### B2C Overview UI
- [x] Create `B2CSummaryCard` widget (Blue gradient, large total, Reguler/SQM breakdown, status breakdown, flagging breakdown)
- [x] Create horizontally scrolling tab selector (All, Reguler, Gold, Plat, Diamond)
- [x] Create `CustomerTypeCard` widget (Grid of cards for Reguler, Gold, Plat, Diamond with inner mini-bars and pills)
- [x] Create `FilterBarB2C` widget (Horizontal scrollable toggle buttons for Jenis, Status, Flagging)

### B2B Overview UI
- [x] Create `B2BGroupSummary` matching Next.js B2BGroupSummary UI
- [x] Create `FilterBarB2B` widget

### Integration
- [x] Integrate all advanced widgets into `admin_dashboard.dart` replacing the current simple summary bars
- [x] Add state variables for B2C active tab, ticketType, statusUpdate, etc.

---

## 2. Implement Assign Technician Modal

### API Services
- [x] Add `ApiConstants.ticketsAssign`
- [x] Add `ApiConstants.ticketsUnassign`
- [x] Implement `assignTicket` method in `TicketApi`
- [x] Implement `unassignTicket` method in `TicketApi`

### Modal UI
- [x] Create `assign_technician_modal.dart` component matching Next.js visual
- [x] Fetch eligible technicians for ticket on load (`res['data']['technicians']` parsing fixed)
- [x] Implement local search by name/NIK
- [x] Build Technician selection tiles indicating currently selected vs. currently assigned
- [x] Implement 'Assign', 'Reassign', and 'Remove Assignment' buttons

### Integration
- [x] Update `ticket_card.dart` to include specific assign button UI layout at the bottom.
- [x] Replace temporary snackbar in `admin_dashboard.dart` with bottom sheet/dialog containing `AssignTechnicianModal`
- [x] Ensure list is refreshed after assignment

## 3. Verification
- [x] Run `flutter analyze` ensuring 0 errors across files.

---

## 4. B2B Cards Overhaul
- [x] Implement `_buildB2BSummaryCard()` matching the exact B2C target screenshot column configuration.
- [x] Implement `_buildB2BCategoryCard()` with corresponding Service Level SLAs times and colors (SQM-CCAN, INDIBIZ, DATIN, RESELLER, WIFI-ID).
- [x] Replace the flat list summary with the new interactive dark-themed graphical GridView grouping.

---

## 5. Global Search & Workzone Filtering
- [x] Add real-time text input `Search...` and `Workzone` dropdown to the top of the Admin Dashboard.
- [x] Wire state parameters to dynamically filter `_tickets` into `_filteredTickets` before updating all B2C/B2B lists and counts.

---

## 6. Fix Menu Semesta Filtering
- [x] Ensure all dropdown filters (Dept, Jenis, Status, Customer) correctly sync and filter the paginated cards.
- [x] Rewrite `admin_semesta_screen` to fetch `getDailyTickets` once, and correctly slice the lists locally resolving the backend pagination offset issues where stats would falsely display.

---

## 7. Next.js Exact Dark/Light Mode Theme Refactoring
- [ ] Create Riverpod `ThemeProvider` managing `ThemeMode`.
- [ ] Convert static `AppColors` into `AppColorsExtension` within `theme.dart` for dynamic resolving.
- [ ] Wrap `main.dart` `MaterialApp` with the consumer adjusting theme variants dynamically.
- [ ] Bulk replace `AppColors.` occurrences with `context.themeExtension` lookups.
- [ ] Inject Theme Toggle (Sun/Moon format) header identical to Next.js across dashboards.
