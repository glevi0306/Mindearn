import { supabase } from '../lib/supabase.js';

export async function getProfile() {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, first_name, last_name')
    .single();
  if (error) throw error;
  return data;
}

export async function updateProfile(updates) {
  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .select()
    .single();
  if (error) throw error;
  return data;
}

// Returns the best available first name for personalization.
// Priority: first_name → first word of name → email prefix
export function getDisplayFirstName(profile, user) {
  if (profile?.first_name) return profile.first_name;
  if (profile?.name) return profile.name.split(' ')[0];
  if (user?.email) return user.email.split('@')[0];
  return '';
}
