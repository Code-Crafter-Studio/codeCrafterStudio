const darkTheme = require("./src/themes/darkTheme");

/** @type {import('tailwindcss').Config} */

export default {
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
  theme: {
    screens: {
      sm: "600px",
      // => @media (min-width: 640px) { ... }

      md: "768px",
      // => @media (min-width: 768px) { ... }

      lg: "1024px",
      // => @media (min-width: 1024px) { ... }

      xl: "1280px",
      // => @media (min-width: 1280px) { ... }

      "2xl": "1536px",
      // => @media (min-width: 1536px) { ... }
      "3xl": "1800px",
      // => @media (min-width: 1800px) { ... }
    },
    extend: {
      colors: { ...darkTheme },
      fontFamily: {
        'twk-everett': ['TWK Everett Bold', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
