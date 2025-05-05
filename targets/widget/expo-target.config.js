/** @type {import('@bacons/apple-targets/app.plugin').ConfigFunction} */
module.exports = (config) => ({
  type: "widget",
  name: "Transit Pulse",
  icon: "https://github.com/expo.png",
  colors: {
    $widgetBackground: "#1B2838",
    $accent: "#4CAF50",
    routeColor: {
      light: "#4CAF50",
      dark: "#81C784",
    },
    delayColor: {
      light: "#F44336",
      dark: "#E57373",
    },
  },
  entitlements: {
    "com.apple.security.application-groups": [
      `group.${config.ios.bundleIdentifier}.transitpulse`,
    ],
  },
});
