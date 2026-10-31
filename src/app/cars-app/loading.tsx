// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: shows straight away while the app's page loads (and lets the
// PIN check run before the page's data arrives).
export default function Loading() {
  return (
    <div className="flex flex-1 items-center justify-center py-24" role="status" aria-label="Loading">
      <span className="size-8 animate-spin rounded-full border-4 border-line border-t-brand" />
    </div>
  );
}
