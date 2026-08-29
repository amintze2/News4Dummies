import { LearnPage } from "@/routes/LearnPage";
import { MyArticlesPage } from "@/routes/MyArticlesPage";
import { WhatsNewPage } from "@/routes/WhatsNewPage";
import { useLocation } from "react-router-dom";
import { TabBar } from "./TabBar";

const TAB_PATHS = ["/", "/my-articles", "/learn"];

export function AppShell() {
  const { pathname } = useLocation();

  return (
    <div className="flex h-svh flex-col">
      <div className="min-h-0 flex-1">
        {TAB_PATHS.map((path) => (
          <div
            key={path}
            hidden={pathname !== path}
            className="h-full overflow-y-auto"
            style={{
              paddingTop: "env(safe-area-inset-top)",
              paddingBottom: "calc(56px + env(safe-area-inset-bottom))",
            }}
          >
            {path === "/" && <WhatsNewPage />}
            {path === "/my-articles" && <MyArticlesPage />}
            {path === "/learn" && <LearnPage />}
          </div>
        ))}
      </div>
      <TabBar />
    </div>
  );
}
