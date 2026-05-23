import { cn } from "@/lib/utils";
import { forwardRef } from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "tertiary" | "danger";
  size?: "sm" | "md" | "lg";
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "primary", size = "md", children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          "inline-flex items-center justify-center font-heading font-semibold rounded-2xl transition-all duration-150 active:scale-95",
          {
            "bg-builder-500 text-white hover:bg-builder-600 shadow-card": variant === "primary",
            "bg-white border-2 border-kraft-500 text-walnut-700 hover:bg-cream-100": variant === "secondary",
            "text-walnut-700 hover:text-walnut-900 underline-offset-2 hover:underline": variant === "tertiary",
            "bg-red-500 text-white hover:bg-red-600": variant === "danger",
          },
          {
            "px-4 py-2 text-sm": size === "sm",
            "px-6 py-3 text-base": size === "md",
            "px-8 py-4 text-lg": size === "lg",
          },
          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);
Button.displayName = "Button";
