# 🌍 NileWing

**NileWing** is a mobile application designed to help **travelers connect during transit periods** — such as layovers and flight delays — based on shared interests, flight details, and proximity.  
The app creates opportunities for **networking, socializing, and collaboration** while waiting for the next leg of a journey.

---

## 🚀 Tech Stack

| Layer | Technology |
|-------|-------------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Django REST Framework |
| **Realtime** | Django Channels (WebSockets) |
| **Database** | PostgreSQL (hosted on [Neon](https://neon.tech)) |
| **Cache / Channel Layer** | Redis |
| **Containerization** | Docker & Docker Compose |
| **Web Server** |  Daphne (ASGI) |

---

## ✨ Key Features

- 🔐 User authentication & profile creation  
- 🛫 Add & manage flight details (departure, layover, destination)  
- 🤝 Smart traveler matching based on:
  - Shared interests  
  - Overlapping flight times  
  - Location proximity  
- 💬 Real-time chat using WebSockets (Django Channels)  
- 📍 Optional location sharing for in-airport meetups  
- 🧭 Modern Flutter UI for smooth user experience  
- 🌐 Secure API communication with JWT  

---

## 🧩 System Architecture

 | **Flutter App ⇄ Django REST API ⇄ PostgreSQL (Neon)** |
 | **↕** |
 | **WebSockets (Django Channels + Redis)** |
 | **↕** |
 | **Docker (Backend + Redis +  Daphne)** |
