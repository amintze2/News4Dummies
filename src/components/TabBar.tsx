import { cn } from "@/lib/utils";
import { Bookmark, GraduationCap, Newspaper } from "lucide-react";
import { NavLink } from "react-router-dom";

const TABS = [
  { to: "/", label: "What's New", icon: Newspaper, end: true },
  { to: "/my-articles", label: "My Articles", icon: Bookmark, end: false },
  { to: "/learn", label: "Learn", icon: GraduationCap, end: false },
];

export function TabBar() {
  return (
    <nav
      className="bg-background border-border fixed inset-x-0 bottom-0 flex border-t"
      style={{ paddingBottom: "env(safe-area-inset-bottom)" }}
    >
      {TABS.map(({ to, label, icon: Icon, end }) => (
        <NavLink
          key={to}
          to={to}
          end={end}
          className={({ isActive }) =>
            cn(
              "flex flex-1 flex-col items-center gap-1 py-2 text-xs",
              isActive ? "text-primary" : "text-muted-foreground",
            )
          }
        >
          <Icon className="size-5" />
          {label}
        </NavLink>
      ))}
    </nav>
  );
}
