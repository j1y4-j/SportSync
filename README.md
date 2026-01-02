SportSync

SportSync is a Flutter-based mobile application that solves two common problems in campus and community sports environments:

Inefficient court booking systems

Underutilized sports equipment owned by players

The app enables real-time court booking, player coordination, and peer-to-peer equipment rental using Firebase.

Problem Statement

Sports courts are often double-booked or poorly managed

Players struggle to coordinate teammates for games

Sports equipment is expensive and often unused

No single platform combines booking + equipment sharing

Solution

SportSync provides a unified platform where users can:

Book sports courts in real time

Invite players and manage booking requests

Rent sports equipment from other users

List personal equipment for rent

All actions update live using Firebase, ensuring consistency and fairness.

Key Features
Court Booking

View available courts and time slots

Book slots with Singles or Doubles logic

Invite friends to join a booking

Slot status auto-updates (free, booked, in use)

Booking Requests

Receive and respond to booking invites

Accept or reject requests in real time

Booking counts update automatically

Equipment Rental

Browse available sports equipment

Send rental requests to owners

Live availability tracking

Put Equipment for Rent

List personal equipment with price and details

Manage availability through Firestore

UI / UX

Clean, consistent design

Light and dark mode support

Smooth animations and interactive cards

Mobile-first user experience

Tech Stack

Flutter (Dart)

Firebase Authentication

Cloud Firestore

Material Design 3

Architecture Overview
lib/
├── screens/
│   ├── home_screen.dart
│   ├── play_screen.dart
│   ├── book_screen.dart
│   ├── rentscreen.dart
│   ├── rentequip.dart
│   ├── add_equipment.dart
│   └── profile_screen.dart
│
├── widgets/
│   └── reusable UI components
│
└── main.dart

Firebase Collections
courts / slots
{
  "bookedBy": ["uid1", "uid2"],
  "invitedUsers": ["uid3"],
  "maxPlayers": 2,
  "status": "booked"
}

bookingRequests
{
  "from": "senderUid",
  "to": "receiverUid",
  "courtId": "courtId",
  "slotId": "slotId",
  "status": "pending"
}

equipment
{
  "ownerId": "uid",
  "name": "Badminton Racket",
  "sport": "Badminton",
  "pricePerHour": 50,
  "description": "Good condition",
  "isAvailable": true
}

How to Run
git clone https://github.com/your-username/SportSync.git
cd SportSync
flutter pub get
flutter run


Firebase setup required:

Enable Authentication

Enable Firestore

Add Firebase config files

Innovation Highlights

Real-time slot conflict prevention using Firestore transactions

Player invitation workflow instead of manual coordination

Peer-to-peer equipment economy within a closed community

Unified sports ecosystem instead of fragmented apps

Future Scope

Push notifications

Equipment availability calendar

Payments and rental duration

Ratings and trust system

Admin dashboard for courts
