module.exports = {
  apps: [
    {
      name: "grateful-giant",
      script: "node_modules/.bin/astro",
      args: "dev --port 4330",
      cwd: "./",
      env: {
        NODE_ENV: "development",
      },
      env_production: {
        NODE_ENV: "production",
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: "1G",
    },
  ],
};
