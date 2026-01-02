
# SportSync

SportSync is a Flutter-based mobile application designed to streamline sports court booking and enable peer-to-peer sports equipment rental within campuses or local communities.

---

## Problem Statement

- Sports courts are often poorly managed and double-booked  
- Players struggle to coordinate teammates for matches  
- Sports equipment is expensive and remains underutilized  
- No unified platform exists for booking courts and renting equipment  

---

## Solution

SportSync provides a single platform where users can:

- Book sports courts in real time  
- Invite players and manage booking requests  
- Rent sports equipment from other users  
- List personal equipment for rent  

All interactions update instantly using Firebase, ensuring fairness, consistency, and transparency.

---

## Key Features

### Court Booking
- Real-time court and slot availability
- Singles and Doubles match selection
- Invite friends to join a booking
- Automatic slot status updates (free, booked, in use)

### Booking Requests
- Receive booking invitations
- Accept or reject requests
- Live notification count updates

### Equipment Rental
- Browse available sports equipment
- Send rental requests to equipment owners
- Real-time availability tracking

### Put Equipment for Rent
- List personal equipment with price and details
- Manage equipment availability

### UI / UX
- Clean and consistent design
- Light and dark mode support
- Smooth animations and interactive cards
- Mobile-first experience

---

## Tech Stack

- Flutter (Dart)
- Firebase Authentication
- Cloud Firestore
- Material Design 3

---

## Project Structure
``` lib/
├── screens/
│ ├── home_screen.dart
│ ├── play_screen.dart
│ ├── book_screen.dart
│ ├── rentscreen.dart
│ ├── rentequip.dart
│ ├── add_equipment.dart
│ └── profile_screen.dart
│
├── widgets/
│ └── reusable UI components
│
└── main.dart
```


---

## Firebase Data Models

### Courts / Slots
```json
{
  "bookedBy": ["uid1", "uid2"],
  "invitedUsers": ["uid3"],
  "maxPlayers": 2,
  "status": "booked"
}
```
---

### Booking Requests
```{
  "from": "senderUid",
  "to": "receiverUid",
  "courtId": "courtId",
  "slotId": "slotId",
  "status": "pending"
}
```
---

### Equipment
```{
  "ownerId": "uid",
  "name": "Badminton Racket",
  "sport": "Badminton",
  "pricePerHour": 50,
  "description": "Good condition",
  "isAvailable": true
}
```
---

### How to Run the Project
``` bash
git clone https://github.com/your-username/SportSync.git
cd SportSync
flutter pub get
flutter run
```
---


## Firebase setup required:

- Enable Firebase Authentication

- Enable Cloud Firestore

- Add Firebase configuration files

## Innovation Highlights

- Real-time slot conflict prevention using Firestore transactions

- Player invitation-based booking system

- Peer-to-peer equipment sharing economy

- Unified sports ecosystem instead of multiple fragmented apps

## Future Enhancements

- Push notifications

- Rental duration and return tracking
  
- In-app messenger
  
- In-app payments

- Ratings and trust system

- Admin dashboard for courts
