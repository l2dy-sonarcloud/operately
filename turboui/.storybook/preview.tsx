import React from "react";
import type { Preview } from "@storybook/react";

import { withThemeByClassName } from "@storybook/addon-themes";
import { RouterDecorator } from "./router";

import "./global.css";
import "./reactdatepicker.css";
import "./reactdatepicker-custom.css";

window.STORYBOOK_ENV = true;

const preview: Preview = {
  parameters: {
    actions: { argTypesRegex: "^on[A-Z].*" },
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    backgrounds: {
      default: "dark",
    },
    layout: "fullscreen",
    viewport: {
      defaultViewport: "reset", // reset the viewport to the default when navigating to a new story
    },
  },
  decorators: [
    RouterDecorator,
    withThemeByClassName({
      themes: {
        light: "light antialiased",
        dark: "dark antialiased",
      },
      defaultTheme: "light",
      parentSelector: "body",
    }),
  ],
};

export default preview;
