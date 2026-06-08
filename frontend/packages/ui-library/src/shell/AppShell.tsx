import type { ReactNode } from "react";

export interface AppShellProps {
  children: ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <>
      <a className="web26-skip-link" href="#main-content">
        Skip to main content
      </a>
      <header className="web26-site-header">
        <div className="web26-container">
          <span className="web26-site-title">Pedro Portella</span>
        </div>
      </header>
      {children}
      <footer className="web26-site-footer">
        <div className="web26-container">Web26</div>
      </footer>
    </>
  );
}
