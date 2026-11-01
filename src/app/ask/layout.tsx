// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: the public website. It uses the portal's own colours and fonts
// (set in System settings), always in the light version.
export default function AskLayout({ children }: LayoutProps<"/ask">) {
  return <div className="ask-light flex min-h-dvh flex-col bg-page text-ink">{children}</div>;
}
