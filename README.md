# AI Boxing Coach

An interactive, AI-powered web application designed to function as a personal boxing trainer and injury-prevention tool. The application leverages real-time computer vision to analyze user stance and form, delivers personalized coaching feedback based on historical errors, and tracks fitness metrics via a custom metabolic calorie expenditure calculator. Built with a responsive, high-fidelity dark-themed user interface optimized for an engaging user experience.

## 🚀 Features

* **Real-Time Form Analysis & Injury Prevention:** Integrates camera-based computer vision tracking to evaluate live boxing stances and punches, providing instant feedback to prevent common training injuries like overextension (boxer's elbow), wrist collapse (boxer's fracture), and rotator cuff strains.
* **Dynamic Calorie Calculator Engine:** Computes real-time metabolic energy expenditure using the Metabolic Equivalent of Task (MET) formula, utilizing the user's weight profile, session duration, and configured intensity level (Low, Medium, or High).
* **Personalized Biomechanical Insights:** Automatically monitors and analyzes frequent posture or stance errors during a session to generate tailored coaching tips to maintain safe skeletal alignment under fatigue.
* **Performance Dashboard:** Displays a comprehensive post-workout summary card detailing total duration, form accuracy percentages, and cumulative calories burned.
* **Premium UI/UX Design:** Features a modern dark theme utilizing a sophisticated typography system (`Outfit` for display headings and `Inter` for clean UI copy) paired with an immersive introductory AI Coach tutorial interface.

## 🛠️ Tech Stack

* **Frontend Framework:** React with TypeScript
* **Styling & Design:** Tailwind CSS / Modern CSS Variables
* **Core Logic:** Gemini API Integration (Computer Vision Stance Parsing & Dynamic Tip Generation)
* **State Management:** React Hooks & Component Architecture

## 📂 Key Architecture & Component Structure

```text
├── src/
│   ├── components/
│   │   ├── Controls.tsx          # Profile inputs (Weight & Intensity selection configurations)
│   │   ├── SessionSummary.tsx    # End-of-session metrics dashboard and calorie card
│   │   ├── Tutorial.tsx          # Onboarding flow and robotic proxy interface layouts
│   │   └── ...
│   ├── types.ts                  # Strictly typed interfaces for workout states and profiles
│   ├── index.css                 # Custom font pairings (Outfit/Inter) and core global styles
│   └── App.tsx                   # Core camera streams, main tracking loops, and layout shell
├── .env.local                    # Local environment configuration
```

## ⚡ Setup & Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/juanfranceschi001/AI-Boxing-Coach.git
   cd ai-boxing-coach
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   Create a `.env.local` file in the root directory and add your API key:
   ```env
   VITE_GEMINI_API_KEY=your_api_key_here
   ```

4. **Launch the Development Server:**
   ```bash
   npm run dev
   ```

After pasting the updated text, commit the changes directly to the main branch with the commit message "Highlight injury prevention and biomechanical features in README".
