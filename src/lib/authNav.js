import { supabase } from './supabase.js';

export function initAuthNav() {
  // Wire sign-out buttons once, before session is known
  document.querySelectorAll('[data-auth-signout]').forEach(btn => {
    btn.addEventListener('click', async () => {
      await supabase.auth.signOut();
      window.location.href = 'index.html';
    });
  });

  // Apply initial state from cached session (reads localStorage, near-instant)
  supabase.auth.getSession().then(({ data: { session } }) => {
    setAuthState(!!session);
  });

  // Keep nav in sync on sign-in, sign-out, token expiry, or other-tab changes
  supabase.auth.onAuthStateChange((_event, session) => {
    setAuthState(!!session);
  });
}

function setAuthState(loggedIn) {
  const show = loggedIn ? 'logged-in' : 'logged-out';
  const hide = loggedIn ? 'logged-out' : 'logged-in';

  // Inline style beats all CSS rules — this is the reliable show/hide mechanism
  document.querySelectorAll(`[data-auth-visible="${show}"]`).forEach(el => {
    el.style.display = 'inline-flex';
  });
  document.querySelectorAll(`[data-auth-visible="${hide}"]`).forEach(el => {
    el.style.removeProperty('display');
  });
}
