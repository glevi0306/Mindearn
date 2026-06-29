import { supabase } from './supabase.js';

export async function requireAuth(redirectTo = 'login.html') {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.replace(redirectTo);
    return false;
  }
  return true;
}
