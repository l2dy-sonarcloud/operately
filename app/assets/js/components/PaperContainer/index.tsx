/**
 * This is a component that renders a paper-like container.
 * It's used in the app to render the main content of the page.
 *
 * Example usage:
 *
 * ```tsx
 * import * as Paper from "@/components/PaperContainer";
 *
 * <Paper.Root>
 *   <Paper.Navigation>
 *     <Paper.NavItem>Projects</Paper.NavItem>
 *     <Paper.NavSeparator />
 *     <Paper.NavItem>Documentation</Paper.NavItem>
 *   </Paper.Navigation>
 *
 *   <Paper.Body>
 *     <h1 className="text-2xl font-bold">Increase Revenue</h1>
 *   </Paper.Body>
 * </Paper.Root>
 * ```
 */

import React from "react";

import classNames from "classnames";

import { Context } from "./Context";

type Size = "tiny" | "small" | "medium" | "large" | "xlarge" | "xxlarge";

const sizes = {
  tiny: "max-w-xl",
  small: "max-w-2xl",
  medium: "max-w-4xl",
  large: "sm:max-w-[90%] lg:max-w-5xl ",
  xlarge: "sm:max-w-[90%] lg:max-w-6xl ",
  xxlarge: "sm:max-w-[90%] lg:max-w-7xl",
};

interface RootProps {
  size?: Size;
  children?: React.ReactNode;
  fluid?: boolean;
  className?: string;
}

export function Root({ size, children, className, fluid = false }: RootProps): JSX.Element {
  size = size || "medium";

  className = classNames(
    className,
    "mx-auto relative",
    "sm:my-10", // no margin on mobile, 10 margin on larger screens
    {
      "w-[90%]": fluid,
      [sizes[size]]: !fluid,
    },
  );

  return (
    <Context.Provider value={{ size }}>
      <div className={className}>{children}</div>
    </Context.Provider>
  );
}

const bodyPaddings = {
  tiny: "px-8 py-6 sm:px-10 sm:py-8",
  small: "px-10 py-8",
  medium: "px-12 py-10",
  large: "px-4 sm:px-12 py-10",
  xlarge: "px-12 py-10",
  xxlarge: "px-16 py-12",
};

interface BodyProps {
  children?: React.ReactNode;
  minHeight?: string;
  className?: string;
  noPadding?: boolean;
  backgroundColor?: string;
  banner?: React.ReactNode;
}

export function Body({
  children,
  minHeight = "none",
  className = "",
  noPadding = false,
  backgroundColor = "bg-surface-base",
  banner,
}: BodyProps) {
  const { size } = React.useContext(Context);
  const padding = noPadding ? "" : bodyPaddings[size];

  const outerClass = classNames(
    "relative",
    backgroundColor,

    // full height on mobile, no min height on larger screens
    "min-h-dvh sm:min-h-0",

    // apply border shadow and rounded corners on larger screens
    "sm:border sm:border-surface-outline",
    "sm:rounded-lg",
    "sm:shadow-xl",
  );

  const innerClass = classNames(padding, { "pt-4": banner }, className);

  return (
    <div className={outerClass}>
      {banner}
      <div className={innerClass} style={{ minHeight: minHeight }}>
        {children}
      </div>
    </div>
  );
}

export function Title({ children }) {
  return (
    <div className="flex items-center gap-4 mb-8">
      <FancyLineSeparator />
      <h1 className="text-4xl font-extrabold text-center">{children}</h1>
      <FancyLineSeparator />
    </div>
  );
}

function FancyLineSeparator() {
  return (
    <div
      className="flex-1"
      style={{
        height: "2px",
        background: "linear-gradient(90deg, var(--color-pink-600) 0%, var(--color-sky-600) 100%)",
      }}
    />
  );
}

export function usePaperSizeHelpers(): { size: Size; negHor: string; negTop: string; horPadding: string } {
  const { size } = React.useContext(Context);

  let negHor = "";
  switch (size) {
    case "small":
      negHor = "-mx-10";
      break;
    case "medium":
      negHor = "-mx-12";
      break;
    case "large":
      negHor = "-mx-4 sm:-mx-12";
      break;
    case "xlarge":
      negHor = "-mx-12";
      break;
    case "xxlarge":
      negHor = "-mx-16";
      break;
    default:
      throw new Error(`Unknown size ${size}`);
  }

  let negTop = "";
  switch (size) {
    case "small":
      negTop = "-mt-8";
      break;
    case "medium":
      negTop = "-mt-10";
      break;
    case "large":
      negTop = "-mt-10";
      break;
    case "xlarge":
      negTop = "-mt-10";
      break;
    case "xxlarge":
      negTop = "-mt-12";
      break;
    default:
      throw new Error(`Unknown size ${size}`);
  }

  let horPadding = "";
  switch (size) {
    case "small":
      horPadding = "px-10";
      break;
    case "medium":
      horPadding = "px-12";
      break;
    case "large":
      horPadding = "px-12";
      break;
    case "xlarge":
      horPadding = "px-12";
      break;
    case "xxlarge":
      horPadding = "px-16";
      break;
    default:
      throw new Error(`Unknown size ${size}`);
  }

  return {
    size: size,
    negHor: negHor,
    negTop: negTop,
    horPadding,
  };
}

export * from "./DimmedSection";
export * from "./Banner";
export * from "./Header";
export * from "./Navigation";
export * from "./Section";
