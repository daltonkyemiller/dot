/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        fg: "rgb(var(--color-fg))",
        bg: "rgb(var(--color-bg))",
        border: "rgb(var(--color-border))",
        muted: "rgb(var(--color-muted))",
      },
    },
  },
  plugins: [],
};
