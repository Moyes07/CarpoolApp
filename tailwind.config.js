/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {margin: {
        '128': '32rem', // Add custom height
        '144': '36rem', // Example of another custom height
      },
    },
  },
  plugins: [],
}