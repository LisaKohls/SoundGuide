# SoundGuide

**By Lisa Kohls and Lisa Salzer**  
Bachelor Thesis | B.Sc. Mobile Medien  
Hochschule der Medien Stuttgart  
Sommersemester 2025

---

## Examiner

Prof. Dr. Ansgar Gerlicher
Axel Braun

---

## About

**SoundGuide** is a prototype developed as part of the Bachelor thesis in the study program *Mobile Medien* at the Hochschule der Medien Stuttgart.

The project explores the combination of **Object Tracking** and **Spatial Audio** using the **Apple Vision Pro** to support **blind and visually impaired individuals** in locating and identifying objects in their environment. The prototype was developed with a focus on usability and accessibility within immersive spaces.

---

## Technologies Used

- Apple Vision Pro (visionOS)
- RealityKit
- ARKit (ObjectTrackingProvider)
- Swift & SwiftUI
- Spatial Audio
- VoiceOver Accessibility
- Xcode 15

---

## Developed By

Lisa Kohls & Lisa Salzer  
Bachelor of Science in Mobile Medien  
Hochschule der Medien Stuttgart, 2025

---

## Setup

### Reference objects
- Use an existing 3D model in `.usdz` format or create your own using **Reality Composer Pro** on a supported iPhone Pro device.
- Ensure the file is **correctly named** to match the app’s expectations.
- Train the object using **CreateML**.
- Export and download the resulting `.referenceObject` file.

### Starting the App
- Clone the repository: git clone https://gitlab.mi.hdm-stuttgart.de/ls228/soundguide.git
- connect the Apple Vision Pro 
- Add the reference Objects to Resources/ReferenceObjects
- run the app

### Hint
- The Object Tracking does not work in the Simulator 

### Tests
- to run the LoadReferenceObjectsTest you need to add the reference Objects manually in: Target → XR-AppTests → Build Phases → Copy Bundle Resources
- run the tests with command + U 

