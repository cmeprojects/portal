// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: runs as soon as the page starts to arrive, before the rest of
// the app loads, so a locked app goes straight to its PIN screen instead of
// loading the home page first. AppAutoLock does the rest once it's running.
export function EarlyLockCheck({ base, pinOff, justSignedIn }: { base: string; pinOff: boolean; justSignedIn: boolean }) {
  if (pinOff || justSignedIn) return null;
  const code = `(function(){try{var p=location.pathname;if(p.indexOf(${JSON.stringify(`${base}/unlock`)})===0)return;if(new URLSearchParams(location.search).has("unlocked"))return;if(sessionStorage.getItem("app-unlocked"))return;location.replace(${JSON.stringify(`${base}/unlock`)});}catch(e){}})();`;
  return <script dangerouslySetInnerHTML={{ __html: code }} />;
}
